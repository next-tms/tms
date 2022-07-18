# frozen_string_literal: true

module SuggestedShipmentAccessorials
  extend ActiveSupport::Concern

  def build_suggested_broker_accessorials(shipment:)
    broker_accessorials = []
    shipment.assumed_accessorials.each do |assumed_accessorial|
      broker_accessorials << shipment.broker.broker_accessorials.find_by(accessorial: assumed_accessorial)
    end

    return if broker_accessorials.blank?

    suggested = 0
    existing_broker_accessorial_ids = shipment.shipment_broker_accessorials.pluck(:broker_accessorial_id)
    broker_accessorials.each do |broker_accessorial|
      next if existing_broker_accessorial_ids.include?(broker_accessorial.id)

      shipment.shipment_broker_accessorials.new(broker_accessorial:, suggested: true)
      suggested += 1
    end

    return if suggested.zero?

    true
  end
end
