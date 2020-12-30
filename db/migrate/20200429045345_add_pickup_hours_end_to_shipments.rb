class AddPickupHoursEndToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :pickup_hours_end, :string
  end
end
