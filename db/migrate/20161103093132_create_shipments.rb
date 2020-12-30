class CreateShipments < ActiveRecord::Migration[5.0]
  def change
    create_table :shipments do |t|
      t.integer :broker_id, foreign_key: true
      t.integer :carrier_id, foreign_key: true
      t.text :lines
      t.string :shipper_name
      t.string :shipper_street
      t.string :shipper_street2
      t.string :shipper_city
      t.string :shipper_zip # Foreign postal codes may contain letters
      t.string :receiver_street
      t.string :receiver_street2
      t.string :receiver_city
      t.string :receiver_zip # Foreign postal codes may contain letters
      t.string :shipper_reference
      t.string :customer_reference
      t.string :pro
      t.string :pickup_confirmation
      t.boolean :picked_up
      t.integer :priority
      t.time :shipper_available_at
      t.time :shipper_unavailable_at
      t.time :receiver_available_at
      t.time :receiver_unavailable_at
      t.integer :load
    end
  end
end
