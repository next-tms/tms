# frozen_string_literal: true

class DispatchShipmentPickupJob < ApplicationJob
  def perform(pickup)
    UserMailer.pickup_service_dispatched(pickup).deliver_later if PickupsService.new(pickup: pickup).dispatch
  end
end
