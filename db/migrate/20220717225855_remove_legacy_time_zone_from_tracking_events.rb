# frozen_string_literal: true

class RemoveLegacyTimeZoneFromTrackingEvents < ActiveRecord::Migration[7.0]
  def change
    remove_column :tracking_events, :legacy_time_zone, :string
  end
end
