class TrackShipmentsJob < ApplicationJob
  def perform(shipment_ids)
    Shipment.where(id: shipment_ids).where.not(broker_carrier: nil).find_each { |shipment| TrackShipmentJob.perform_later(shipment) }
  end
end
