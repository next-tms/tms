class ChangeAddressesOnShipments < ActiveRecord::Migration[5.1]
  def change
    remove_column :shipments, :shipper_street
    remove_column :shipments, :shipper_street2
    remove_column :shipments, :shipper_city
    remove_column :shipments, :shipper_zip
    remove_column :shipments, :receiver_street
    remove_column :shipments, :receiver_street2
    remove_column :shipments, :receiver_city
    remove_column :shipments, :receiver_zip
  end
end
