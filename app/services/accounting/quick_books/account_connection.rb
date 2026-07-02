module Accounting
  module QuickBooks
    class AccountConnection < Connection
      def all(**)
        request { |service| service.all }.select { |account| listable?(account) }.map { |account| build(account) }
      end

      private

      def listable?(account)
        Account::LISTABLE_SUB_TYPES.include?(account.account_sub_type) && account.classification == 'Liability'
      end
    end
  end
end
