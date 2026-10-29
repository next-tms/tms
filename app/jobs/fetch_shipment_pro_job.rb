class FetchShipmentProJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_pro
    Shipment::TrackJob.perform_later(shipment) unless shipment.pro.blank?
  end
end
