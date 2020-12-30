class AddTruckLoadToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :truckload, :boolean, default: false
  end
end
