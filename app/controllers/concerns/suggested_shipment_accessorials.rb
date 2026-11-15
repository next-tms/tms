module SuggestedShipmentAccessorials
  extend ActiveSupport::Concern

  def build_suggested_broker_accessorials(shipment:)
    return [] if shipment.quote_only? || shipment_params[:accessorials_has_been_suggested].present?

    return [] unless request.format.html?

    [shipment.receiver_address, shipment.shipper_address].each(&:standardize)

    broker_accessorial_ids = shipment.shipment_broker_accessorials.map(&:broker_accessorial_id)
    broker_accessorials = shipment.suggested_broker_accessorials.reject do |broker_accessorial|
      broker_accessorial_ids.include?(broker_accessorial.id)
    end

    broker_accessorials.each { |broker_accessorial| shipment.shipment_broker_accessorials.build(broker_accessorial:, suggested: true) }
  end
end
