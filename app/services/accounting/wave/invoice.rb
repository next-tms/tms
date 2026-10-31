module Accounting
  module Wave
    class Invoice < Accounting::Invoice
      SELECTION = 'id createdAt status invoiceNumber customer { id } amountDue { minorUnitValue } total { minorUnitValue }'.freeze

      class << self
        def attributes_from(node)
          {
            balance: Accounting.money(node.dig('amountDue', 'minorUnitValue')&.to_i),
            created_at: node['createdAt'],
            customer_id: node.dig('customer', 'id'),
            document_number: node['invoiceNumber'],
            email_status: email_status(node['status']),
            total: Accounting.money(node.dig('total', 'minorUnitValue')&.to_i)
          }
        end

        def collection_key = 'invoices'
        def connection = @connection ||= InvoiceConnection.new(self)
        def create_input(invoice, business_id) = { businessId: business_id, **shared_input(invoice) }.compact
        def create_mutation = 'invoiceCreate'
        def list_arguments = 'sort: [CREATED_AT_DESC]'
        def node_key = 'invoice'
        def patch_input(invoice) = { id: invoice.id, **shared_input(invoice) }.compact
        def patch_mutation = 'invoicePatch'
        def selection = SELECTION

        private

        def email_status(status) = ['SENT', 'VIEWED'].include?(status) ? 'EmailSent' : status

        def items_input(invoice)
          product_id = Product.id

          invoice.line_items.to_a.map do |line_item|
            item = { productId: product_id, description: line_item.description }
            item.merge!(quantity: line_item.quantity, unitPrice: line_item.unit_price) if line_item.kind == :sales
            item.compact
          end
        end

        def shared_input(invoice)
          {
            customerId: invoice.customer_id,
            dueDate: invoice.due_date&.iso8601,
            invoiceDate: invoice.transaction_date&.to_date&.iso8601,
            invoiceNumber: invoice.document_number,
            items: items_input(invoice),
            poNumber: invoice.tracking_number&.to_s,
            status: 'SAVED'
          }
        end
      end

      def pdf = self.class.connection.pdf(self)
    end
  end
end
