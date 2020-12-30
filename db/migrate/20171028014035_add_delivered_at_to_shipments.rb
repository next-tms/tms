class AddDeliveredAtToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :delivered_at, :date
  end
end
