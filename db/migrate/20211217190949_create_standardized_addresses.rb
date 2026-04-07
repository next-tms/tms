class CreateStandardizedAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :standardized_addresses do |t|
      t.datetime :google_places_spot_updated_at
      t.datetime :open_street_map_result_updated_at
      t.datetime :smarty_streets_result_updated_at
      t.integer :addresses_count
      t.references :country, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.string :city
      t.string :key, index: true
      t.string :latitude
      t.string :longitude
      t.string :postal_code
      t.string :street
      t.string :street2
      t.string :time_zone
      t.text :google_places_spot_cached
      t.text :open_street_map_result_cached
      t.text :smarty_streets_result_cached

      t.timestamps
    end
  end
end
