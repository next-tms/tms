# frozen_string_literal: true

module QuickbooksApiClient
  class Customers < Base
    def create(broker_customer)
      customer = broker_customer.to_quickbooks_customer

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.create(customer)
      end
    end

    def update(broker_customer)
      quickbooks_customer = broker_customer.quickbooks_customer
      return create(broker_customer) if quickbooks_customer.blank?

      quickbooks_customer = find(quickbooks_customer.id)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.update(customer, sparse: true)
      end
    end

    def find_all
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.query
      end
    end

    def find(id)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)

        begin
          service.fetch_by_id(id)
        rescue Quickbooks::IntuitRequestException => e
          nil
        end
      end
    end

    def find_by_name(name)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        results = service.find_by(:company_name, name)

        results.count == 1 ? results.first : nil
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
