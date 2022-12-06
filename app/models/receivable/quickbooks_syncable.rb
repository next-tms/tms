# frozen_string_literal: true

module Receivable::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    def create_quickbooks_invoice
      return nil unless broker.intuit_account&.connected?

      return update_quickbooks_invoice unless quickbooks_invoice.blank?

      broker_customer.create_quickbooks_customer if broker_customer.quickbooks_customer.blank?

      result = QuickbooksAPIClient::Invoices.new(broker:).create(self)
      return @quickbooks_invoice = nil if result.blank?

      update!(invoiced: true, quickbooks_invoice_id: result.id)
      @quickbooks_invoice = result
    end

    def quickbooks_invoice
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_invoice unless @quickbooks_invoice.blank?

      result = nil

      unless quickbooks_invoice_id.blank?
        result = QuickbooksAPIClient::Invoices.new(broker:).find(quickbooks_invoice_id)
      end
      unless result.blank?
        persisted? ? update_columns(quickbooks_invoice_id: result.id) : self.quickbooks_invoice_id = result.id
        return @quickbooks_invoice = result
      end

      result = QuickbooksAPIClient::Invoices.new(broker:).find_by_doc_number(shipment.load_id)
      unless result.blank?
        persisted? ? update_columns(quickbooks_invoice_id: result.id) : self.quickbooks_invoice_id = result.id
        return @quickbooks_invoice = result
      end

      nil
    end

    def quickbooks_invoice_pdf
      return nil if !broker.intuit_account&.connected? || quickbooks_invoice.blank?

      data = QuickbooksAPIClient::Invoices.new(broker:).pdf(quickbooks_invoice)
      return nil if data.blank?

      if data.include?('errorCode=')
        # Sample Error Response when fetching Invoice PDF Content
        # <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<IntuitResponse time=\"2022-09-08T01:21:01.679-07:00\"
        # xmlns=\"http://schema.intuit.com/finance/v3\">\n <Fault type=\"SERVICE\">\n <Error code=\"3001\">\n <Message>message=ThrottleExceeded;
        # errorCode=003001; statusCode=429</Message>\n  </Error>\n  </Fault>\n</ IntuitResponse>\n"
        sleep(10)
        data = QuickbooksAPIClient::Invoices.new(broker:).pdf(quickbooks_invoice)
      end

      filename = "#{shipment.load_id} Invoice.pdf"
      path = File.join(Dir.tmpdir, filename)

      File.binwrite(path, data)

      blob = ActiveStorage::Blob.create_and_upload!(io: File.open(path), filename:, content_type: 'application/pdf')
      invoice.attach(blob)
    end

    def update_from_quickbooks_invoice
      return if quickbooks_invoice.blank?

      now = DateTime.current

      # Using update_columns so we can bypass the validation that recalculates amounts
      update_columns(balance_cents: (quickbooks_invoice.balance.to_f * 100).to_i)
      update_columns(paid_at: now) if quickbooks_invoice.balance.zero?
      update_columns(total_cents: (quickbooks_invoice.total.to_f * 100).to_i)

      if !sent? && (quickbooks_invoice.balance.zero? || quickbooks_invoice.email_status == 'EmailSent')
        update_columns(sent_at: now)
      end

      reload
    end

    def update_quickbooks_invoice
      return false unless broker.intuit_account&.connected?

      return create_quickbooks_invoice if quickbooks_invoice.blank?

      shipment.broker_customer.create_quickbooks_customer unless shipment.broker_customer.quickbooks_customer.present?

      result = QuickbooksAPIClient::Invoices.new(broker:).update(self)
      return @quickbooks_invoice = nil if result.blank?

      update!(invoiced: true, quickbooks_invoice_id: result.id)
      @quickbooks_invoice = result
    end
  end
end
