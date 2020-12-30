class RemoveShipmentFromAddresses < ActiveRecord::Migration[5.1]
  def change
    remove_column :addresses, :shipment_id, :integer
  end
end
