# frozen_string_literal: true

class CreateShipmentBrokerBolJob < ApplicationJob
  def perform(domain:, shipment:)
    return if shipment.broker_bol_valid?

    pdf = PdfRenderer.new(domain: domain, shipment: shipment, view: 'shipments/documents_bol')
    shipment.broker_bol.attach(io: StringIO.new(pdf.data), filename: "#{shipment.load_id} BOL.pdf", content_type: 'application/pdf')
    shipment.update_columns(broker_bol_shipment_fingerprint: shipment.broker_documents_fingerprint)
  end
end
