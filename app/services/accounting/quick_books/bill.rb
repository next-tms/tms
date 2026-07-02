module Accounting
  module QuickBooks
    class Bill < Accounting::Bill
      EXPENSE_ACCOUNT_ID = '62' # @todo Make configurable

      class << self
        def attributes_from(bill)
          { balance: Accounting.money(bill.balance), document_number: bill.doc_number, total: Accounting.money(bill.total) }
        end

        def connection = @connection ||= DocumentConnection.new(self)
        def find_field(attribute) = { document_number: :doc_number }.fetch(attribute, attribute)

        def serialize(bill, model = nil)
          model ||= ::Quickbooks::Model::Bill.new
          model.line_items = []
          model.doc_number = bill.document_number
          model.due_date = bill.due_date
          model.mailing_address = QuickBooks.physical_address(bill.mailing_address)
          model.private_note = bill.private_note
          model.vendor_id = bill.vendor_id

          bill.line_items.to_a.each { |line_item| model.line_items << line_item_model(line_item) }
          model
        end

        def service_class = ::Quickbooks::Service::Bill

        private

        def line_item_model(line_item)
          model = ::Quickbooks::Model::BillLineItem.new(amount: line_item.amount, description: line_item.description)
          model.account_based_expense_item! { |detail| detail.account_id = EXPENSE_ACCOUNT_ID }
          model
        end
      end
    end
  end
end
