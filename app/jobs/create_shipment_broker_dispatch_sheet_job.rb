# frozen_string_literal: true

class CreateShipmentBrokerDispatchSheetJob < ApplicationJob
  queue_as :high_priority

  def perform(domain:, shipment:)
    return if shipment.broker_dispatch_sheet_valid? || shipment.incomplete?

    shipment.broadcast_document_generation_started('Dispatch Sheet')

    pdf = PdfRenderer.new(domain:, shipment:, view: 'shipments/documents_dispatch_sheet')
    shipment.broker_dispatch_sheet.attach(io: StringIO.new(pdf.data),
                                          filename: "#{shipment.load_id} Dispatch Sheet.pdf", content_type: 'application/pdf')
    shipment.update_columns(broker_dispatch_sheet_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated('Dispatch Sheet')
  end
end
