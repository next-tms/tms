module Accounting
  class LineItem
    include ActiveModel::Model

    attr_accessor :account_id, :amount, :description, :kind, :linked_transactions, :quantity, :unit_price

    def initialize(kind: :description, linked_transactions: [], **attributes)
      super(kind:, linked_transactions:, **attributes)
    end
  end
end
