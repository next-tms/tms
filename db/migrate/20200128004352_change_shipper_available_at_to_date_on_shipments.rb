class ChangeShipperAvailableAtToDateOnShipments < ActiveRecord::Migration[6.0]
  def up
    remove_column :shipments, :shipper_available_at, :string
    add_column :shipments, :shipper_available_at, :datetime
    Shipment.find_each do |shipment|
      shipment.shipper_available_at = shipment.created_at
      shipment.save
    end
  end

  def down
    remove_column :shipments, :shipper_available_at, :datetime
    add_column :shipments, :shipper_available_at, :string
  end
end
