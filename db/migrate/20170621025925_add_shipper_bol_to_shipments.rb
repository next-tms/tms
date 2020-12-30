class AddShipperBolToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :shipper_bol, :string
  end
end
