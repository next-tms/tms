class CreateShipmentItems < ActiveRecord::Migration[5.1]
  def change
    create_table :shipment_items do |t|
      t.references :shipment, foreign_key: true
      t.references :item, foreign_key: true
    end
  end
end
