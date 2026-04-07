class AddRegionToTrackingEvents < ActiveRecord::Migration[6.1]
  def up
    add_reference :tracking_events, :region, null: true, foreign_key: true

    say 'Populate tracking_events.region_id'
    Region.all.includes(:country).find_each do |region|
      TrackingEvent
      .where('TRIM(state) ILIKE ?', region.abbreviation)
      .update_all(country_id: region.country.id, region_id: region.id, state: nil)
    end
  end

  def down
    remove_column :tracking_events, :region_id
  end
end
