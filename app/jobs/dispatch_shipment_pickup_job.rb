# frozen_string_literal: true

class DispatchShipmentPickupJob < ApplicationJob
  queue_as :high_priority

  def perform(pickup)
    UserMailer.pickup_service_dispatched(pickup).deliver_later if PickupsService.new(pickup:).dispatch
  end
end
