# frozen_string_literal: true

module DocumentableService
  class Shipment::CreateBrokerBOLJob < ApplicationJob
    queue_as :high_priority

    def perform(shipment)
      content_type = 'application/pdf'
      filename = "#{shipment.load_id} BOL.pdf"
      io = StringIO.new(PDFService::Renderer.call('shipments/documents_bol', locals: { shipment: }))

      blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

      shipment.broker_bol.attach(blob)

      shipment.broadcast_new_document_generated(:broker_bol)
    end
  end
end
