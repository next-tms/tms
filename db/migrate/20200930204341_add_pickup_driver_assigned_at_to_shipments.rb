class AddPickupDriverAssignedAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :pickup_driver_assigned_at, :datetime
  end
end
