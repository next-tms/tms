# frozen_string_literal: true

class TrackShipmentsJob < ApplicationJob
  def perform(shipment_ids)
    shipments = Shipment.where(id: shipment_ids)

    shipments.find_each do |shipment|
      TrackShipmentJob.perform_later(shipment)
    end
  end
end
