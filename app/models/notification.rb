# == Schema Information
#
# Table name: notifications
#
# @!attribute id
#   @return []
# @!attribute params
#   @return [Hash]
# @!attribute read_at
#   @return [Time]
# @!attribute recipient_type
#   @return [String]
# @!attribute type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute recipient_id
#   @return []
#
# Indexes
#
#  index_notifications_on_read_at    (read_at)
#  index_notifications_on_recipient  (recipient_type,recipient_id)
#
class Notification < ApplicationRecord
  include Noticed::Model
  include ActionView::RecordIdentifier

  belongs_to :recipient, polymorphic: true

  after_create :broadcast_unread_notifications_by_turbo

  def broadcast_unread_notifications_by_turbo
    broadcast_update_to(
      self.recipient,
      :notifications,
      target: "#{dom_id(self.recipient)}_unread_notifications_count",
      html: self.recipient.notifications.unread.count
    )
  end

  def self.notification_types
    %w[
      shipment:new_shipment
      shipment:booked_at
      shipment:delivered_at
      shipment:delivery_eta_on
      shipment:delivery_appointment_at
      shipment:delivery_appointment_on
      shipment:departed_origin_terminal_at
      shipment:out_for_delivery_at
      shipment:picked_up_at
      shipment:canceled_at
      shipment:dispatcher_id

      document:carrier_bol
      document:carrier_pod
      document:broker_quote
      document:broker_dispatch_sheet
      document:broker_bol

      pickup:pickup_service_dispatched
    ]
  end
end
