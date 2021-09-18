# frozen_string_literal: true

class CreateShipmentBrokerQuoteJob < ApplicationJob
  def perform(domain:, shipment:)
    return if shipment.broker_quote_valid?

    pdf = PdfRenderer.new(domain: domain, shipment: shipment, view: 'shipments/documents_quote')
    shipment.broker_quote.attach(io: StringIO.new(pdf.data), filename: "#{shipment.load_id} Quote.pdf", content_type: 'application/pdf')
    shipment.update_columns(broker_quote_shipment_fingerprint: shipment.fingerprint)
  end
end
