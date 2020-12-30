class AddCountryAlpha2ToTrackingEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :tracking_events, :country_alpha2, :string, limit: 2
  end
end
