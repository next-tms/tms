class FetchShipmentProJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_pro
    TrackShipmentJob.perform_later(shipment) if shipment.pro.present?
  end
end
