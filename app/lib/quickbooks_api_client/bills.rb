# frozen_string_literal: true

module QuickbooksAPIClient
  class Bills < Base
    def create(payment_transaction)
      bill = build_bill(payment_transaction)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(bill)
        rescue *QuickbooksAPIClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksAPIClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        rescue Quickbooks::IntuitRequestException => e
          raise unless e.message.include?('Duplicate Document Number Error')

          result = find_by_doc_number(bill.load_id)
          return result unless result.blank?

          raise
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

    def find_by_doc_number(doc_number)
      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)

          results = service.find_by(:doc_number, doc_number)
          if results.count == 1
            results.first
          else
            results.entries.find do |entry|
              entry.private_note.exclude?('Void')
            end
          end
        end
      end
    end

    def update(payment_transaction)
      bill = payment_transaction.quickbooks_bill
      return create(payment_transaction) if bill.blank?

      bill = find(bill.id)
      bill = build_bill(payment_transaction, bill)

      broker.intuit_account.perform_authenticated_request do |access_token|
        execute_service_call do
          service = build_service(access_token)
          service.update(bill, sparse: true)
        end
      end
    end

    private

    def build_bill(payment_transaction, bill = nil)
      bill = Quickbooks::Model::Bill.new if bill.blank?
      bill.line_items = [] # for update

      bill.bill_email = nil # TODO: Add support for this
      bill.doc_number = payment_transaction.shipment.load_id.to_s
      bill.due_date = payment_transaction.due_on
      bill.private_note = payment_transaction.notes

      vendor_id = payment_transaction.broker_carrier.quickbooks_vendor_id ||
                  payment_transaction.broker_carrier.create_quickbooks_vendor.id
      bill.vendor_id = vendor_id

      billing_address = payment_transaction.broker_carrier.check_mailing_address&.to_quickbooks_physical_address

      unless billing_address.blank?
        billing_address.line1 = payment_transaction.broker_carrier.carrier.name
        billing_address.line2 = billing_address.line1
        bill.mailing_address = billing_address
      end

      amount = (payment_transaction.paid_cents.to_f / 100)
      description = build_line_item_description(payment_transaction)

      line_item = Quickbooks::Model::BillLineItem.new(amount:, description:)

      # TODO: Definitely fix this
      line_item.account_based_expense_item! { |detail| detail.account_id = '62' }

      bill.line_items << line_item

      bill
    end

    def build_line_item_description(payment_transaction)
      parts = [ "#{payment_transaction.broker.name} Load #{payment_transaction.shipment.load_id}" ]

      unless payment_transaction.shipment.pro.blank?
        parts << "#{payment_transaction.broker_carrier.name} Pro #{payment_transaction.shipment.pro}"
      end

      "Shipping (#{parts.join(' / ')})"
    end

    def build_service(access_token)
      service = Quickbooks::Service::Bill.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token

      service
    end
  end
end
