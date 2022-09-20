# frozen_string_literal: true

module QuickbooksApiClient
  class BillPayments < Base
    def create(payment)
      bill_payment = build_bill_payment(payment)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(bill_payment)
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        rescue Quickbooks::IntuitRequestException => e
          raise unless e.message.include?('Duplicate Document Number Error')

          result = find_by_doc_number(bill_payment.load_id)
          return result unless result.blank?

          raise
        end
      end
    end

    def destroy(payment)
      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.delete(payment.quickbooks_bill_payment)
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

    def update(payment)
      bill_payment = payment.quickbooks_bill_payment
      return create(payment) if bill_payment.blank?

      bill_payment = find(bill_payment.id)
      bill_payment = build_bill_payment(payment, bill_payment)

      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.update(bill_payment, sparse: true)
        end
      end
    end

    # private

    def build_account_base_reference(account)
      Quickbooks::Model::BaseReference.new(account.id, name: account.name)
    end

    def build_bill_payment(payment, bill_payment = nil)
      bill_payment = Quickbooks::Model::BillPayment.new if bill_payment.blank?
      bill_payment.line_items = [] # for update

      if payment.bank.credit_card?
        bill_payment.credit_card_payment = build_bill_payment_credit_card(payment)
        bill_payment.pay_type = 'CreditCard'
      elsif payment.bank.checking?
        bill_payment.check_payment = build_bill_payment_check(payment)
        bill_payment.pay_type = 'Check'
      else
        raise StandardError, "Bank id=#{payment.bank.id}: Unknown kind: #{payment.bank.kind}"
      end

      bill_payment.doc_number = payment.id
      bill_payment.line_items = build_bill_payment_line_items(payment)
      bill_payment.private_note = build_bill_payment_private_note(payment)
      bill_payment.total = (payment.payment_transactions.sum(:paid_cents).to_f / 100)

      vendor_id = payment.broker_carrier.quickbooks_vendor_id ||
                  payment.broker_carrier.create_quickbooks_vendor.id
      bill_payment.vendor_id = vendor_id

      bill_payment
    end

    def build_bill_payment_line_items(payment)
      payment_transactions = payment.payment_transactions.where('balance_cents > ?', 0)

      payment_transactions.where(quickbooks_bill_id: nil).each(&:create_quickbooks_bill)

      payment_transactions.map do |payment_transaction|
        amount = (payment_transaction.paid_cents.to_f / 100)
        description = payment_transaction.shipment.pro.blank? ? nil : payment_transaction.shipment.pro
        linked_transactions = [
          Quickbooks::Model::LinkedTransaction.new(txn_id: payment_transaction.quickbooks_bill_id, txn_type: 'Bill')
        ]

        Quickbooks::Model::BillPaymentLineItem.new(amount:, description:, linked_transactions:)
      end
    end

    def build_bill_payment_check(payment)
      payment.bank.create_quickbooks_account if payment.bank.quickbooks_account_id.blank?

      bill_payment_check = Quickbooks::Model::BillPaymentCheck.new
      bill_payment_check.bank_account_ref = build_account_base_reference(payment.bank.quickbooks_account)
      bill_payment_check.print_status = 'NotSet'

      bill_payment_check
    end

    def build_bill_payment_credit_card(payment)
      payment.bank.create_quickbooks_account if payment.bank.quickbooks_account_id.blank?

      bill_payment_credit_card = Quickbooks::Model::BillPaymentCreditCard.new
      bill_payment_credit_card.cc_account_ref = build_account_base_reference(payment.bank.quickbooks_account)

      bill_payment_credit_card
    end

    def build_bill_payment_private_note(payment)
      parts = []

      # This sometimes doesn't match payment.bank.kind (ACH, Venmo, etc) so we note it:
      parts << "TMS Payment #{payment.id}"
      parts << "#{payment.payment_method.name} #{payment.method_reference}"
      parts << "\n" # extra line break before transaction-specific notes

      parts += payment.payment_transactions.map do |payment_transaction|
        payment_transaction.notes.blank? ? nil : "#{payment_transaction.shipment.pro}:\n#{payment_transaction.notes}"
      end

      parts.compact.join("\n").strip
    end

    def build_service(access_token)
      service = Quickbooks::Service::BillPayment.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token

      service
    end
  end
end
