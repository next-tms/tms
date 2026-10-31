class CancelShipmentJob < ApplicationJob
  def perform(shipment)
    shipment.assign_attributes(canceled_at: DateTime.current, updated_by_id: nil)

    shipment.save
  end
end
