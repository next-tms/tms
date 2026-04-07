class RenameTimeZoneToLegacyTimeZoneOnTrackingEvents < ActiveRecord::Migration[6.1]
  def change
    rename_column :tracking_events, :time_zone, :legacy_time_zone
  end
end
