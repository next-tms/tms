# frozen_string_literal: true

class CancelShipmentsJob < ApplicationJob
  def perform
    Shipment.pending_quotation.active.where('updated_at < ?', 21.days.ago).find_each do |shipment|
      CancelShipmentJob.perform_later(shipment)
    end
  end
end
