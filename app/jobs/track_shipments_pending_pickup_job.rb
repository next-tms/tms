class TrackShipmentsPendingPickupJob < ApplicationJob
  def perform
    shipment_ids = Shipment.active.pending_pickup.where.not(pro: nil).ids

    TrackShipmentsJob.perform_later(shipment_ids)
  end
end
