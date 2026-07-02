module Accounting
  class BillPayment < Base
    attribute :account_id
    attribute :account_name
    attribute :document_number
    attribute :line_items
    attribute :pay_type
    attribute :private_note
    attribute :total
    attribute :transaction_date
    attribute :vendor_id
  end
end
