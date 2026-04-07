class CreatePreferredBrokerCarriers < ActiveRecord::Migration[7.0]
  def change
    create_table :preferred_broker_carriers do |t|
      t.references :broker_customer, null: false, foreign_key: true
      t.references :broker_carrier, null: false, foreign_key: true

      t.timestamps
    end
  end
end
