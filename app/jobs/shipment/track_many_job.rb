class Shipment::TrackManyJob < ApplicationJob
  def perform(shipment_ids)
    Shipment.where(id: shipment_ids).where.not(broker_carrier: nil).find_each do |shipment|
      Shipment::TrackJob.perform_later(shipment)
    end
  end
end
