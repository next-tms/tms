module QuickbooksAPIClient
  class Vendors < Base
    def create(broker_carrier)
      vendor = broker_carrier.to_quickbooks_vendor

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(vendor)
        rescue *QuickbooksAPIClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksAPIClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find_all
      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.all
        end
      end
    end

    def find(id)
      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.fetch_by_id(id)
        end
      end
    end

    def find_by_name(name)
      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)

          results = service.find_by(:company_name, name)
          results.count == 1 ? results.first : nil
        end
      end
    end

    def build_service(access_token)
      service = Quickbooks::Service::Vendor.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token

      service
    end
  end
end
