# frozen_string_literal: true

module DocumentableService
  class Shipment::CreateBrokerDispatchSheetJob < ApplicationJob
    queue_as :high_priority

    def perform(shipment)
      content_type = 'application/pdf'
      filename = "#{shipment.load_id} Dispatch Sheet.pdf"
      io = StringIO.new(PDFService::Renderer.call('shipments/documents_dispatch_sheet', locals: { shipment: }))

      blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

      shipment.skip_documentable_callback = true
      shipment.broker_dispatch_sheet.attach(blob)
      shipment.broadcast_new_document_generated(:broker_dispatch_sheet)
    end
  end
end
