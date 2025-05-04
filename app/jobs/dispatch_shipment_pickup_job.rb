# frozen_string_literal: true

class DispatchShipmentPickupJob < ApplicationJob
  queue_as :high_priority

  def perform(pickup)
    success = TransponderService::CreatePickup.call(pickup)
    return unless success

    PickupNotifier
    .with(pickup:, pickup_action_type: :pickup_service_dispatched)
    .deliver(pickup.shipment.users_to_notify)
  end
end
