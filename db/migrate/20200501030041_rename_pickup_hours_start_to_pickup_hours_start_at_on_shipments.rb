class RenamePickupHoursStartToPickupHoursStartAtOnShipments < ActiveRecord::Migration[6.0]
  def change
    rename_column :shipments, :pickup_hours_start, :pickup_hours_start_at
  end
end
