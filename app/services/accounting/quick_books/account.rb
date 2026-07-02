module Accounting
  module QuickBooks
    class Account < Accounting::Account
      LISTABLE_SUB_TYPES = %w[Checking CreditCard].freeze
      SUB_TYPES = { checking: 'Checking', credit_card: 'CreditCard' }.freeze

      class << self
        def attributes_from(account)
          { account_number: account.acct_num, name: account.name, sub_type: SUB_TYPES.invert[account.account_sub_type] }
        end

        def connection = @connection ||= AccountConnection.new(self)
        def find_field(attribute) = attribute

        def serialize(account, model = nil)
          model ||= ::Quickbooks::Model::Account.new
          model.account_sub_type = SUB_TYPES.fetch(account.sub_type)
          model.account_type = 'Bank'
          model.acct_num = account_number(account.account_number)
          model.classification = ::Quickbooks::Model::Account::LIABILITY
          model.name = account_name(account.name)
          model
        end

        def service_class = ::Quickbooks::Service::Account

        private

        def account_name(name) = name.gsub(':', ' -').gsub('"', '').squish[..99]
        def account_number(number) = number.blank? ? nil : (number.length > 20 ? "#{number[..16]}..." : number)
      end
    end
  end
end
