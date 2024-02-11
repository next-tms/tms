# frozen_string_literal: true

class DispatchShipmentPickupJob < ApplicationJob
  queue_as :high_priority

  def perform(pickup)
    success = TransponderService::CreatePickup.call(pickup)
    return unless success

    notification = PickupNotification.with(pickup:, pickup_action_type: :pickup_service_dispatched)
    notification.deliver_later(pickup.shipment.users_to_notify)
  end
end
