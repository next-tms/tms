class AddGooglePlacesSpotUpdatedAtToAddresses < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :google_places_spot_updated_at, :datetime
  end
end
