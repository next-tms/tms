# frozen_string_literal: true

class CreateShipmentBrokerDispatchSheetJob < ApplicationJob
  queue_as :high_priority

  def perform(broker_documents_fingerprint:, domain:, shipment:)
    unless shipment.can_create_broker_dispatch_sheet? && shipment.broker_documents_fingerprint == broker_documents_fingerprint
      return
    end

    shipment.broadcast_outdated_document(:broker_dispatch_sheet)

    pdf = PdfRenderer.new(domain:, shipment:, view: 'shipments/documents_dispatch_sheet')

    blob = ActiveStorage::Blob.create_and_upload!(
      content_type: 'application/pdf',
      filename: "#{shipment.load_id} Dispatch Sheet.pdf",
      io: StringIO.new(pdf.data)
    )
    shipment.broker_dispatch_sheet.attach(blob)

    shipment.update_columns(broker_dispatch_sheet_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated(:broker_dispatch_sheet)
  end
end
