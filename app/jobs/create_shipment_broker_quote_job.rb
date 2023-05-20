# frozen_string_literal: true

class CreateShipmentBrokerQuoteJob < ApplicationJob
  queue_as :high_priority

  def perform(broker_documents_fingerprint:, shipment:)
    unless shipment.can_create_broker_quote? && shipment.broker_documents_fingerprint == broker_documents_fingerprint
      return
    end

    shipment.broadcast_outdated_document(:broker_quote)

    content_type = 'application/pdf'
    filename = "#{shipment.load_id} Quote.pdf"
    io = StringIO.new(PDFService::Renderer.call('shipments/documents_quote', locals: { shipment: }))

    blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

    shipment.broker_quote.attach(blob)
    shipment.update!(broker_quote_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated(:broker_quote)
  end
end
