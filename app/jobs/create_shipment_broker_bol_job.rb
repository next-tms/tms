# frozen_string_literal: true

class CreateShipmentBrokerBolJob < ApplicationJob
  queue_as :high_priority

  def perform(domain:, shipment:)
    return if shipment.broker_bol_valid? || shipment.incomplete?

    shipment.broadcast_document_generation_started('Bill of Landing')

    pdf = PdfRenderer.new(domain:, shipment:, view: 'shipments/documents_bol')
    shipment.broker_bol.attach(io: StringIO.new(pdf.data), filename: "#{shipment.load_id} BOL.pdf",
                               content_type: 'application/pdf')
    shipment.update_columns(broker_bol_shipment_fingerprint: shipment.broker_documents_fingerprint)

    shipment.broadcast_new_document_generated('Bill of Landing')
  end
end
