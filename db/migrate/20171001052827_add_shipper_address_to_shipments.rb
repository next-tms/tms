class AddShipperAddressToShipments < ActiveRecord::Migration[5.1]
  def change
    add_reference :shipments, :shipper_address, foreign_key: { to_table: :addresses }
  end
end
