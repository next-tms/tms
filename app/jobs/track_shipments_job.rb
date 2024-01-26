# frozen_string_literal: true

class TrackShipmentsJob < ApplicationJob
  def perform(shipment_ids)
    Shipment.where(id: shipment_ids).find_each { |shipment| TrackShipmentJob.perform_later(shipment) }
  end
end
