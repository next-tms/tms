# frozen_string_literal: true

class AddTimeZoneNameToTrackingEvents < ActiveRecord::Migration[6.1]
  def up
    add_column :tracking_events, :time_zone_name, :string

    say 'Populate tracking_events.time_zone_name'
    TrackingEvent.all.find_each do |tracking_event|
      next unless tracking_event.legacy_time_zone.is_a?(Timezone::Zone)
      tracking_event.update_columns(time_zone_name: tracking_event.legacy_time_zone.name)
    end
  end

  def down
    remove_column :users, :time_zone_name
  end
end
