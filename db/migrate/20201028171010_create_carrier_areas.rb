class CreateCarrierAreas < ActiveRecord::Migration[6.0]
  def change
    create_table :carrier_areas do |t|
      t.references :carrier, null: false, foreign_key: true
      t.references :area, null: false, foreign_key: true
      t.monetize :per_pallet_rate
    end
  end
end
