module Accounting
  module QuickBooks
    class BillPayment < Accounting::BillPayment
      class << self
        def attributes_from(bill_payment)
          {
            document_number: bill_payment.doc_number,
            total: Accounting.money(bill_payment.total),
            transaction_date: bill_payment.txn_date
          }
        end

        def connection = @connection ||= Connection.new(self)
        def find_field(attribute) = attribute

        def serialize(bill_payment, model = nil)
          model ||= ::Quickbooks::Model::BillPayment.new
          model.line_items = []
          model.doc_number = bill_payment.document_number
          model.private_note = bill_payment.private_note
          model.total = bill_payment.total&.amount
          model.vendor_id = bill_payment.vendor_id
          assign_payment(model, bill_payment)

          bill_payment.line_items.to_a.each { |line_item| model.line_items << line_item_model(line_item) }
          model
        end

        def service_class = ::Quickbooks::Service::BillPayment

        private

        def account_reference(bill_payment)
          ::Quickbooks::Model::BaseReference.new(bill_payment.account_id, name: bill_payment.account_name)
        end

        def assign_payment(model, bill_payment)
          case bill_payment.pay_type
          when :check
            model.pay_type = 'Check'
            model.check_payment = ::Quickbooks::Model::BillPaymentCheck.new.tap do |check|
              check.bank_account_ref = account_reference(bill_payment)
              check.print_status = 'NotSet'
            end
          when :credit_card
            model.pay_type = 'CreditCard'
            model.credit_card_payment = ::Quickbooks::Model::BillPaymentCreditCard.new.tap do |card|
              card.cc_account_ref = account_reference(bill_payment)
            end
          end
        end

        def line_item_model(line_item)
          linked = line_item.linked_transactions.map do |transaction|
            ::Quickbooks::Model::LinkedTransaction.new(txn_id: transaction[:txn_id], txn_type: transaction[:txn_type])
          end

          ::Quickbooks::Model::BillPaymentLineItem.new(
            amount: line_item.amount,
            description: line_item.description,
            linked_transactions: linked
          )
        end
      end
    end
  end
end
