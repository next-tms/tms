class DropStandardizedAddresses < ActiveRecord::Migration[8.1]
  def up
    remove_reference :addresses, :standardized_address, foreign_key: true, index: true
    drop_table :standardized_addresses
  end

  def down
    create_table :standardized_addresses do |t|
      t.integer :addresses_count
      t.string :city
      t.string :country_alpha2, limit: 2, null: false
      t.text :google_places_spot_cached
      t.datetime :google_places_spot_updated_at, precision: nil
      t.string :key
      t.string :latitude
      t.string :longitude
      t.text :open_street_map_result_cached
      t.datetime :open_street_map_result_updated_at, precision: nil
      t.string :postal_code
      t.string :region_iso31662, null: false
      t.text :smarty_streets_result_cached
      t.datetime :smarty_streets_result_updated_at, precision: nil
      t.string :street
      t.string :street2
      t.string :time_zone_name, null: false
      t.timestamps
      t.index :country_alpha2
      t.index :key
      t.index :region_iso31662
    end

    add_reference :addresses, :standardized_address, foreign_key: true, index: true
  end
end
