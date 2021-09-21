# frozen_string_literal: true

class CreateShipmentBrokerDispatchSheetJob < ApplicationJob
  def perform(domain:, shipment:)
    return if shipment.broker_dispatch_sheet_valid?

    pdf = PdfRenderer.new(domain: domain, shipment: shipment, view: 'shipments/documents_dispatch_sheet')
    shipment.broker_dispatch_sheet.attach(io: StringIO.new(pdf.data), filename: "#{shipment.load_id} Dispatch Sheet.pdf", content_type: 'application/pdf')
    shipment.update_columns(broker_dispatch_sheet_shipment_fingerprint: shipment.fingerprint)
  end
end
