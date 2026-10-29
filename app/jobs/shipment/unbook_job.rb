class Shipment::UnbookJob < ApplicationJob
  def perform(shipment) = shipment.update(booked_at: nil, updated_by_id: nil)
end
