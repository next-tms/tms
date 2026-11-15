class RemoveNamesFromShipments < ActiveRecord::Migration[8.1]
  def change
    remove_column :shipments, :receiver_name, :string
    remove_column :shipments, :shipper_name, :string
  end
end
