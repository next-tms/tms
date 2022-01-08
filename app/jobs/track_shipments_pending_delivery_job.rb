# frozen_string_literal: true

class TrackShipmentsPendingDeliveryJob < ApplicationJob
  def perform
    TrackShipmentsJob.perform_later(Shipment.active.pending_delivery.ids)
  end
end
