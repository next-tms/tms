module QuickbooksAPIClient
  class Accounts < Base
    def create(bank)
      account = build_account(bank)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(account)
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

          service.all.select do |account|
            %w[Checking CreditCard].include?(account.account_sub_type) && account.classification == 'Liability'
          end
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

          results = service.find_by(:name, name)
          results.count == 1 ? results.first : nil
        end
      end
    end

    def update(bank)
      account = bank.quickbooks_account
      return create(account) if account.blank?

      account = find(account.id)
      account = build_account(bank, account)

      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.update(account, sparse: true)
        end
      end
    end

    private

    def build_account(bank, account = nil)
      account = Quickbooks::Model::Account.new if account.blank?

      account.account_type = 'Bank'
      account.account_sub_type = (bank.credit_card? ? 'CreditCard' : 'Checking')
      account.acct_num = if bank.account_number.blank?
                           nil
                         elsif bank.account_number.length > 20
                           "#{bank.account_number[..16]}..."
                         else
                           bank.account_number
                         end
      account.classification = Quickbooks::Model::Account::LIABILITY
      account.name = bank.quickbooks_account_name

      Rails.logger.debug(account)

      account
    end

    def build_service(access_token)
      service = Quickbooks::Service::Account.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token

      service
    end
  end
end
