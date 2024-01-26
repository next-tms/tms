# frozen_string_literal: true

class TrackShipmentsPendingDeliveryJob < ApplicationJob
  def perform
    shipment_ids = Shipment.active.pending_delivery.where.not(pro: nil).ids

    TrackShipmentsJob.perform_later(shipment_ids)
  end
end
