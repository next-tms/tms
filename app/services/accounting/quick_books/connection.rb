module Accounting
  module QuickBooks
    class Connection
      BACKOFF_EXCEPTIONS = [ ::Quickbooks::ServiceUnavailable, ::Quickbooks::TooManyRequests ].freeze
      MAX_RETRIES = 10
      RETRY_WAIT_SECONDS = 30

      attr_reader :record_class

      def initialize(record_class) = @record_class = record_class

      def all(**) = request { |service| service.all }.map { |object| build(object) }
      def create(record) = build(request { |service| service.create(record_class.serialize(record)) })
      def destroy(record) = request { |service| service.delete(service.fetch_by_id(record.id)) }
      def find(id) = build(request(return_nil_on_404: true) { |service| service.fetch_by_id(id) })

      def find_by(conditions)
        field, value = conditions.first
        build(select_match(request { |service| service.find_by(record_class.find_field(field), value) }))
      end

      def pdf(record) = request(return_nil_on_404: true) { |service| service.pdf(service.fetch_by_id(record.id)) }

      def update(record)
        existing = request(return_nil_on_404: true) { |service| service.fetch_by_id(record.id) }
        return create(record) if existing.blank?

        build(request { |service| service.update(record_class.serialize(record, existing), sparse: true) })
      end

      private

      def authenticator = Accounting.integration.service
      def build(object) = object.present? ? record_class.new(object.id, loaded: true, **record_class.attributes_from(object)) : nil

      def request(return_nil_on_404: false)
        authenticator.perform_authenticated_request do |access_token|
          with_backoff { yield service(access_token) }
        rescue ::Quickbooks::IntuitRequestException => e
          raise unless return_nil_on_404 || e.message == 'InternalServerError'

          nil
        end
      end

      def select_match(results) = results.count == 1 ? results.first : nil

      def service(access_token)
        record_class.service_class.new.tap do |service|
          service.access_token = access_token
          service.company_id = authenticator.realm_id
        end
      end

      def with_backoff
        tries = 0
        begin
          yield
        rescue *BACKOFF_EXCEPTIONS
          raise if tries >= MAX_RETRIES

          tries += 1
          sleep(RETRY_WAIT_SECONDS)
          retry
        end
      end
    end
  end
end
