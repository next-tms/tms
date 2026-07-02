module Accounting
  class Invoice < Base
    attribute :balance
    attribute :billing_address
    attribute :billing_email_address
    attribute :created_at
    attribute :customer_id
    attribute :document_number
    attribute :due_date
    attribute :email_status
    attribute :line_items
    attribute :private_note
    attribute :ship_date
    attribute :shipping_address
    attribute :shipping_method
    attribute :total
    attribute :tracking_number
    attribute :transaction_date
  end
end
