module Accounting
  class Bill < Base
    attribute :balance
    attribute :document_number
    attribute :due_date
    attribute :line_items
    attribute :mailing_address
    attribute :private_note
    attribute :total
    attribute :vendor_id
  end
end
