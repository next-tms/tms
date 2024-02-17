# frozen_string_literal: true

module DocumentableService
  class Shipment::CreateBrokerDispatchSheetJob < ApplicationJob
    queue_as :high_priority

    def perform(broker_documents_fingerprint:, shipment:)
      if [shipment.broker_documents_fingerprint, shipment.broker_dispatch_sheet_shipment_fingerprint]
         .include?(broker_documents_fingerprint)
        return
      end

      shipment.broadcast_outdated_document(:broker_dispatch_sheet)

      content_type = 'application/pdf'
      filename = "#{shipment.load_id} Dispatch Sheet.pdf"
      io = StringIO.new(PDFService::Renderer.call('shipments/documents_dispatch_sheet', locals: { shipment: }))

      blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

      shipment.broker_dispatch_sheet.attach(blob)
      shipment.update!(broker_dispatch_sheet_shipment_fingerprint: broker_documents_fingerprint)

      shipment.broadcast_new_document_generated(:broker_dispatch_sheet)
    end
  end
end
