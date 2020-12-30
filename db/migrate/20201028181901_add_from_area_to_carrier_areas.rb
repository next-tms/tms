class AddFromAreaToCarrierAreas < ActiveRecord::Migration[6.0]
  def change
    add_reference :carrier_areas, :from_area, null: false, foreign_key: { to_table: :areas }
  end
end
