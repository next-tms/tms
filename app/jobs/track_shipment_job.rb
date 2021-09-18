# frozen_string_literal: true

class TrackShipmentJob < ApplicationJob
  def perform(shipment)
    shipment.update_tracking_events
  end
end
