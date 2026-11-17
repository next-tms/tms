module DocumentableService
  class Shipment::CreateBrokerEBOLJob < ApplicationJob
    class << self
      def render(shipment) = EBOL::Exporter.call(shipment).then { |document| document.to_json if EBOL.valid?(document) }
    end

    queue_as :high_priority

    def perform(shipment)
      content = self.class.render(shipment)
      return if content.nil?

      blob = ActiveStorage::Blob.create_and_upload!(
        content_type: Mime[:ebol].to_s,
        filename: "#{shipment.load_id}.ebol.json",
        io: StringIO.new(content)
      )

      shipment.skip_documentable_callback = true
      shipment.broker_ebol.attach(blob)
      shipment.broadcast_new_document_generated(:broker_ebol)
    end
  end
end
