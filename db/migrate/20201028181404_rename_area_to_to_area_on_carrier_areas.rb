class RenameAreaToToAreaOnCarrierAreas < ActiveRecord::Migration[6.0]
  def change
    rename_column :carrier_areas, :area_id, :to_area_id
  end
end
