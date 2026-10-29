class Shipment::UnbookManyJob < ApplicationJob
  def perform
    Shipment.booked.where(picked_up_at: nil).where('booked_at < ?', 1.week.ago).find_each do |shipment|
      Shipment::UnbookJob.perform_later(shipment)
    end
  end
end
