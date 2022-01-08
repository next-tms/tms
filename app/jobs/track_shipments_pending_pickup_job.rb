# frozen_string_literal: true

class TrackShipmentsPendingPickupJob < ApplicationJob
  def perform
    TrackShipmentsJob.perform_later(Shipment.active.pending_pickup.ids)
  end
end
