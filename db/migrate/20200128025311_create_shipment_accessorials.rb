class CreateShipmentAccessorials < ActiveRecord::Migration[6.0]
  def change
    create_table :shipment_accessorials do |t|
      t.references :shipment, null: false, foreign_key: true
      t.references :accessorial, null: false, foreign_key: true
    end
  end
end
