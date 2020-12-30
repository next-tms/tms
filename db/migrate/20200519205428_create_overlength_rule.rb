class CreateOverlengthRule < ActiveRecord::Migration[6.0]
  def change
    create_table :overlength_rules do |t|
      t.references :broker_carrier, null: false, foreign_key: true
      t.integer :min_length
      t.integer :max_length
      t.monetize :cost
    end
  end
end
