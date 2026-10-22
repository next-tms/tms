class AddShipmentIdToItems < ActiveRecord::Migration[8.1]
  class Item < ActiveRecord::Base; end
  class ShipmentItem < ActiveRecord::Base; end

  def up
    add_reference :items, :shipment, foreign_key: true

    say 'populate(:items, :shipment_id)'
    ShipmentItem.order(:id).find_each do |shipment_item|
      item = Item.find(shipment_item.item_id)
      item = item.dup unless item.shipment_id.nil?

      item.shipment_id = shipment_item.shipment_id
      item.save!(validate: false)
    end

    Item.where(shipment_id: nil).delete_all

    change_column_null :items, :shipment_id, false
  end

  def down = remove_reference(:items, :shipment, foreign_key: true)
end
