class AddCountryToTrackingEvents < ActiveRecord::Migration[6.1]
  def up
    add_reference :tracking_events, :country, null: true, foreign_key: true

    say 'Populate tracking_events.country_id'
    TrackingEvent.all.update_all(country_id: Country.find_by_alpha2_code('US').id)

    change_column_null :tracking_events, :country_id, :false
  end

  def down
    remove_reference :tracking_events, :country_id
  end
end
