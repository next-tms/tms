class TrackShipmentJob < ApplicationJob
  def perform(shipment)
    shipment.update_tracking_events
  end
end
