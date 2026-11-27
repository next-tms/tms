module SuggestedShipmentAccessorials
  extend ActiveSupport::Concern

  def build_suggested_accessorials(shipment:)
    return [] if shipment.quote_only? || shipment_params[:accessorials_has_been_suggested].present?

    return [] unless request.format.html?

    [shipment.receiver_address, shipment.shipper_address].each(&:standardize)

    shipment.suggested_accessorials.each { |accessorial| shipment.shipment_accessorials.build(accessorial:, suggested: true) }
  end
end
