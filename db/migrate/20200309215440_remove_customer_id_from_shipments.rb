class RemoveCustomerIdFromShipments < ActiveRecord::Migration[6.0]
  def change
    remove_column :shipments, :customer_id
  end
end
