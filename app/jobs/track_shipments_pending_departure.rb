# frozen_string_literal: true

class TrackShipmentsPendingDepartureJob < ApplicationJob
  def perform
    TrackShipmentsJob.perform_later(Shipment.active.pending_departure.ids)
  end
end
