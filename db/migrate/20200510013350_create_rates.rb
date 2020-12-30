class CreateRates < ActiveRecord::Migration[6.0]
  def change
    create_table :rates do |t|
      t.references :broker_carrier, null: false, foreign_key: true
      t.references :tracking_carrier, null: true, foreign_key: { to_table: :carriers }
      t.references :broker_customer, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.monetize :cost
      t.text :error
      t.datetime :expires_at
      t.string :reference
      t.text :request
      t.text :response
      t.integer :transit_days
      t.boolean :with_calculated_freight_classes
      t.timestamps
    end
  end
end
