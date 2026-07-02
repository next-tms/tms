module Accounting
  module QuickBooks
    class Invoice < Accounting::Invoice
      class << self
        def attributes_from(invoice)
          {
            balance: Accounting.money(invoice.balance),
            created_at: invoice.meta_data&.create_time,
            customer_id: invoice.customer_ref&.value,
            document_number: invoice.doc_number,
            email_status: invoice.email_status,
            total: Accounting.money(invoice.total)
          }
        end

        def connection = @connection ||= DocumentConnection.new(self)
        def find_field(attribute) = { document_number: :doc_number }.fetch(attribute, attribute)

        def serialize(invoice, model = nil)
          model ||= ::Quickbooks::Model::Invoice.new
          model.line_items = []
          model.billing_address = QuickBooks.physical_address(invoice.billing_address)
          model.billing_email_address = invoice.billing_email_address
          model.customer_id = invoice.customer_id
          model.doc_number = invoice.document_number
          model.due_date = invoice.due_date
          model.ship_date = invoice.ship_date
          model.ship_method_ref = ship_method_ref(invoice.shipping_method)
          model.shipping_address = QuickBooks.physical_address(invoice.shipping_address)
          model.tracking_num = invoice.tracking_number
          model.txn_date = invoice.transaction_date

          invoice.line_items.to_a.each { |line_item| model.line_items << line_item_model(line_item) }
          model
        end

        def service_class = ::Quickbooks::Service::Invoice

        private

        def line_item_model(line_item)
          case line_item.kind
          when :description
            ::Quickbooks::Model::InvoiceLineItem.new(description: line_item.description, detail_type: 'DescriptionOnly')
          when :sales
            model = ::Quickbooks::Model::InvoiceLineItem.new(amount: line_item.amount, description: line_item.description)
            model.sales_item! do |detail|
              detail.quantity = line_item.quantity
              detail.unit_price = line_item.unit_price
            end
            model
          end
        end

        def ship_method_ref(shipping_method)
          return if shipping_method.blank?

          name = shipping_method[..30]
          ::Quickbooks::Model::BaseReference.new(name, value: name)
        end
      end

      def pdf = self.class.connection.pdf(self)
    end
  end
end
