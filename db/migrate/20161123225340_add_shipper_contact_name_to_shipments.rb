class AddShipperContactNameToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :shipper_contact_name, :string
  end
end
