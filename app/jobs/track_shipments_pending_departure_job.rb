class TrackShipmentsPendingDepartureJob < ApplicationJob
  def perform
    shipment_ids = Shipment.active.pending_departure.where.not(pro: nil).ids

    Shipment::TrackManyJob.perform_later(shipment_ids)
  end
end
