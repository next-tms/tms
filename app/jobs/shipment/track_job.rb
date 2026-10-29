class Shipment::TrackJob < ApplicationJob
  def perform(shipment)
    shipment.update_tracking_events
  end
end
