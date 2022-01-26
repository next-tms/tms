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

    def find_by_doc_number(doc_number)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        results = service.find_by(:doc_number, doc_number)

        results.count == 1 ? nil : results.first
      end
    end

    def update(receivable)
      # invoice = build_invoice(receivable)
      invoice = find(receivable.quickbooks_invoice.id)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        service.update(invoice, sparse: true)
      end
    end

    private

    def build_invoice(receivable, invoice: nil)
      if invoice.blank?
        invoice = Quickbooks::Model::Invoice.new(
          billing_address:,
          customer_id: receivable.broker_customer.quickbooks_customer_id,
          txn_date: DateTime.current.in_time_zone(receivable.broker_customer.broker.time_zone),
          doc_number: receivable.shipment.load_id.to_s
        )
      end

      billing_address = receivable.broker_customer.office_address.to_quickbooks_physical_address
      billing_address.line2 = billing_address.line1
      billing_address.line1 = receivable.broker_customer.customer.name

      references = []
      unless receivable.shipment.shipper_reference.blank?
        references << "Shipper Ref: #{receivable.shipment.shipper_reference}"
      end
      unless receivable.shipment.customer_reference.blank?
        references << "PO Ref: #{receivable.shipment.customer_reference}"
      end
      references = references.reject(&:blank?)

      unless references.blank?
        line_item = Quickbooks::Model::InvoiceLineItem.new(
          amount: 0,
          description: references.join("\n")
        )

        line_item.sales_item! do |detail|
          detail.unit_price = 0
          detail.quantity = 0
          # detail.item_id = 500
        end

        invoice.line_items << line_item
      end

      unless receivable.broker_customer.office_address.proper(', ') == receivable.shipment.shipper_address.proper(', ')
        line_item = Quickbooks::Model::InvoiceLineItem.new(
          amount: 0,
          description: "Pickup from:\n\n#{receivable.shipment.shipper_name}\n#{receivable.shipment.shipper_address.proper("\n")}"
        )

        line_item.sales_item! do |detail|
          detail.unit_price = 0
          detail.quantity = 0
          # detail.item_id = 500
        end

        invoice.line_items << line_item
      end

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
