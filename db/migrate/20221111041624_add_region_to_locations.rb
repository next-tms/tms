class AddRegionToLocations < ActiveRecord::Migration[7.0]
  def up
    add_reference :locations, :region, null: true, foreign_key: true

    say 'populate(:locations, :region_id)'
    region = Country.find_by(alpha2_code: 'US').regions.find_by(abbreviation: 'CA')
    Area.find(1).locations.update_all(region_id: region.id)

    change_column_null :locations, :region_id, false
  end

  def down
    remove_column :locations, :region_id
  end
end
