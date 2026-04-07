# frozen_string_literal: true

class BumpNoticedFromV1ToV2 < ActiveRecord::Migration[7.1]
  class TempNotification < ApplicationRecord
    self.inheritance_column = nil
    self.table_name = 'notifications'
  end

  class TempEvent < ApplicationRecord
    self.table_name = 'noticed_events'
    self.inheritance_column = :_type_disabled
  end

  class TempNotificationV2 < ApplicationRecord
    self.table_name = 'noticed_notifications'
    self.inheritance_column = :_type_disabled
  end

  def up
    TempNotification.find_each do |notification|
      attributes = notification.attributes.slice('type', 'created_at', 'updated_at')
      attributes[:type] = "Notifiers::#{attributes["type"].to_s.sub("Notification", "Notifier")}"

      begin
        params = Noticed::Coder.load(notification.params)
      rescue
        next
      end

      next if !params.is_a?(Hash) || params['noticed_error']

      notifications_attributes = [
                                   {
                                     type: "#{attributes[:type].sub("Notification", "Notifier")}::Notification",
                                     recipient_type: notification.recipient_type,
                                     recipient_id: notification.recipient_id,
                                     read_at: notification.read_at,
                                     seen_at: notification.read_at,
                                     created_at: notification.created_at,
                                     updated_at: notification.updated_at
                                   }
                                 ]
      record = params.delete('user') || params.delete('account')

      event_attrs = attributes.merge(params:, notifications_attributes:)
      event_attrs[:record] = record if record.present?

      begin
        Noticed::Event.create!(event_attrs)
      rescue => e
        Rails.logger.error("Failed to create event from notification #{notification.id}: #{e}")
      end
    end

    drop_table('notifications')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
