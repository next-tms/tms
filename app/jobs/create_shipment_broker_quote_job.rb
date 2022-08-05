# frozen_string_literal: true

class CreateShipmentBrokerQuoteJob < ApplicationJob
  queue_as :high_priority

  def perform(domain:, shipment:)
    return unless shipment.can_create_broker_quote?

    shipment.broadcast_outdated_document(:broker_quote)

    pdf = PdfRenderer.new(domain:, shipment:, view: 'shipments/documents_quote')

    shipment.broker_quote.attach(
      content_type: 'application/pdf',
      filename: "#{shipment.load_id} Quote.pdf",
      io: StringIO.new(pdf.data)
    )

    shipment.update_columns(broker_quote_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated(:broker_quote)
  end
end
