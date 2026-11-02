module DocumentableService
  class Shipment::CreateBrokerBOLJob < ApplicationJob
    class << self
      def render(shipment) = PDFService::Renderer.call('shipments/documents_bol', locals: { shipment: })
    end

    queue_as :high_priority

    def perform(shipment)
      content_type = 'application/pdf'
      filename = "#{shipment.load_id} BOL.pdf"
      io = StringIO.new(self.class.render(shipment))

      blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

      shipment.skip_documentable_callback = true
      shipment.broker_bol.attach(blob)
      shipment.broadcast_new_document_generated(:broker_bol)
    end
  end
end
