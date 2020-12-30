class CreateUpchargeRules < ActiveRecord::Migration[6.0]
  def change
    create_table :upcharge_rules do |t|
      t.references :broker_customer, null: false, foreign_key: true
      t.references :packaging, null: false, foreign_key: true
      t.integer :max
      t.integer :min
      t.monetize :upcharge
      t.float :upcharge_percentage
      t.timestamps
    end
  end
end
