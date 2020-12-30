class AddOutForDeliveryAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :out_for_delivery_at, :datetime
  end
end
