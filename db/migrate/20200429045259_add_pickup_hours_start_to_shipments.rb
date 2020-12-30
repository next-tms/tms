class AddPickupHoursStartToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :pickup_hours_start, :string
  end
end
