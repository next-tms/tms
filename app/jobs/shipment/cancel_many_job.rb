class Shipment::CancelManyJob < ApplicationJob
  def perform
    Shipment.pending_quotation.active.where('updated_at < ?', 21.days.ago).find_each do |shipment|
      Shipment::CancelJob.perform_later(shipment)
    end
  end
end
