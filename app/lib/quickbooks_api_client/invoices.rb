# frozen_string_literal: true

module QuickbooksApiClient
  class Invoices < Base
    def create(receivable)
      invoice = build_invoice(receivable)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.create(invoice)
      end
    end

    def find_all
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.query
      end
    end

    def find(id)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)

        begin
          service.fetch_by_id(id)
        rescue Quickbooks::IntuitRequestException => e
          nil
        end
      end
    end

    def update(receivable)
      invoice = build_invoice(receivable)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.create(invoice)
      end
    end

    private

    def build_invoice(receivable)
      invoice = Quickbooks::Model::Invoice.new(
        customer_id: receivable.broker_customer.quickbooks_customer_id,
        txn_date: DateTime.current.in_time_zone(receivable.broker_customer.broker.time_zone),
        doc_number: receivable.shipment.load_id.to_s
      )

      receivable.receivable_items.each do |receivable_item|
        amount = (receivable_item.charge_cents.to_f / 100)

        line_item = Quickbooks::Model::InvoiceLineItem.new(amount:, description: receivable_item.description)

        line_item.sales_item! do |detail|
          detail.unit_price = amount
          detail.quantity = 1
          # detail.item_id = 500
        end

        invoice.line_items << line_item
      end

      invoice
    end

    def build_service(access_token)
      service = Quickbooks::Service::Invoice.new
      service.company_id = broker.intuit_account.realm_id
      service.access_token = access_token
  
      service
    end
  end
end
