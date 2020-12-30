class CreatePricingRules < ActiveRecord::Migration[6.0]
  def change
    create_table :pricing_rules do |t|
      t.references :carrier_area, null: false, foreign_key: true
      t.references :broker_carrier, null: false, foreign_key: true
      t.monetize :cost_per_pallet
      t.integer :max_pallets
      t.integer :min_pallets

      t.index :max_pallets
      t.index :min_pallets
      t.timestamps
    end
  end
end
