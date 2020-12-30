class AddGooglePlacesSpotCachedToAddresses < ActiveRecord::Migration[6.0]
  def change
    add_column :addresses, :google_places_spot_cached, :text
  end
end
