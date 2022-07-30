# frozen_string_literal: true

class CreateShipmentBrokerQuoteJob < ApplicationJob
  queue_as :high_priority

  def perform(domain:, shipment:)
    return if shipment.broker_quote_valid?

    shipment.broadcast_document_generation_started('Quote')

    pdf = PdfRenderer.new(domain:, shipment:, view: 'shipments/documents_quote')
    shipment.broker_quote.attach(io: StringIO.new(pdf.data), filename: "#{shipment.load_id} Quote.pdf",
                                 content_type: 'application/pdf')
    shipment.update_columns(broker_quote_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated('Quote')
  end
end
