# frozen_string_literal: true

class TrackShipmentsPendingDepartureJob < ApplicationJob
  def perform
    shipment_ids = Shipment.active.pending_departure.where.not(pro: nil).ids

    TrackShipmentsJob.perform_later(shipment_ids)
  end
end
