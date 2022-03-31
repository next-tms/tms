# frozen_string_literal: true

module QuickbooksApiClient
  class Customers < Base
    def create(broker_customer)
      customer = broker_customer.to_quickbooks_customer

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(customer)
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def update(broker_customer)
      quickbooks_customer = broker_customer.quickbooks_customer
      return create(broker_customer) if quickbooks_customer.blank?

      customer = broker_customer.to_quickbooks_customer

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.update(customer, sparse: true)
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find_all
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.query
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find(id)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.fetch_by_id(id)
        rescue Quickbooks::IntuitRequestException
          nil
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find_by_name(name)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          results = service.find_by(:company_name, name)
          results.count == 1 ? results.first : nil
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def build_service(access_token)
      service = Quickbooks::Service::Customer.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token

      service
    end
  end
end
