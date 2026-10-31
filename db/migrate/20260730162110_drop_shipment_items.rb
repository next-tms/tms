class DropShipmentItems < ActiveRecord::Migration[8.1]
  class Item < ActiveRecord::Base; end
  class ShipmentItem < ActiveRecord::Base; end

  def up = drop_table(:shipment_items)

  def down
    create_table(:shipment_items) do |t|
      t.references :shipment, foreign_key: true
      t.references :item, foreign_key: true
    end

    say 'populate(:shipment_items)'
    Item.where.not(shipment_id: nil).find_each { |item| ShipmentItem.create!(shipment_id: item.shipment_id, item_id: item.id) }
  end
end
