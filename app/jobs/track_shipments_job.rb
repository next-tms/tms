class TrackShipmentsJob < ApplicationJob
  def perform(shipment_ids)
    shipment_ids.each do |shipment_id|
      Shipment.find(shipment_id).update_tracking_events
    end
  end
end
