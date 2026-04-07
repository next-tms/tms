class FetchShipmentProJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_pro
    TrackShipmentJob.perform_later(shipment) unless shipment.pro.blank?
  end
end
