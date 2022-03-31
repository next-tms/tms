# frozen_string_literal: true

module QuickbooksApiClient
  class Invoices < Base
    def create(receivable)
      invoice = build_invoice(receivable)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.create(invoice)
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find_all
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.query
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find(id)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.fetch_by_id(id)
        rescue Quickbooks::IntuitRequestException
          nil
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def find_by_doc_number(doc_number)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          results = service.find_by(:doc_number, doc_number)
          results.count == 1 ? results.first : nil
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def pdf(invoice)
      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.pdf(invoice)
        rescue Quickbooks::IntuitRequestException
          nil
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    def update(receivable)
      invoice = receivable.quickbooks_invoice
      return create(receivable) if invoice.blank?

      invoice = find(invoice.id)

      broker.intuit_account.perform_authenticated_request do |access_token|
        service = build_service(access_token)
        tries = 0

        begin
          service.update(invoice, sparse: true)
        rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
          raise if tries > 10

          sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
          retry
        end
      end
    end

    private

    def build_invoice(receivable, invoice: nil)
      if invoice.blank?
        invoice = Quickbooks::Model::Invoice.new(
          billing_email_address: receivable.broker_customer.receivables_contact.email,
          customer_id: receivable.broker_customer.quickbooks_customer_id,
          doc_number: receivable.shipment.load_id.to_s,
          txn_date: DateTime.current.in_time_zone(receivable.broker_customer.broker.time_zone)
        )
      end

      billing_address = receivable.broker_customer.office_address.to_quickbooks_physical_address
      billing_address.line2 = billing_address.line1
      billing_address.line1 = receivable.broker_customer.customer.name
      invoice.billing_address = billing_address

      shipping_address = receivable.shipment.receiver_address.to_quickbooks_physical_address
      shipping_address.line2 = shipping_address.line1
      shipping_address.line1 = receivable.shipment.receiver_name
      invoice.shipping_address = shipping_address

      carrier = if receivable.shipment.broker_carrier.blank?
                  nil
                elsif receivable.shipment.broker_carrier.carrier.acts_as_broker
                  receivable.shipment.tracking_carrier.blank? ? receivable.shipment.broker_carrier.carrier : receivable.shipment.tracking_carrier
                else
                  receivable.shipment.broker_carrier.carrier
                end

      unless carrier.blank?
        ship_method_ref = Quickbooks::Model::BaseReference.new(carrier.name[..30], value: carrier.name[..30])

        invoice.ship_method_ref = ship_method_ref
      end

      invoice.tracking_num = receivable.shipment.load_id

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
          description: references.join("\n"),
          detail_type: 'DescriptionOnly'
        )

        invoice.line_items << line_item
      end

      unless receivable.broker_customer.office_address.proper(', ') == receivable.shipment.shipper_address.proper(', ')
        line_item = Quickbooks::Model::InvoiceLineItem.new(
          description: "Pickup from:\n\n#{receivable.shipment.shipper_name}\n#{receivable.shipment.shipper_address.proper("\n")}",
          detail_type: 'DescriptionOnly'
        )

        invoice.line_items << line_item
      end

      invoice.due_date = receivable
                         .due_by
                         .in_time_zone(receivable.broker_customer.broker.time_zone)
                         .to_date

      invoice.ship_date = receivable
                          .shipment
                          .picked_up_at
                          .in_time_zone(receivable.broker_customer.broker.time_zone)
                          .to_date

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
