# frozen_string_literal: true

class DispatchShipmentPickupJob < ApplicationJob
  def perform(pickup)
    if PickupsService.new(pickup: pickup).dispatch
      UserMailer.pickup_service_dispatched(pickup.shipment).deliver_later
    end
  end
end
