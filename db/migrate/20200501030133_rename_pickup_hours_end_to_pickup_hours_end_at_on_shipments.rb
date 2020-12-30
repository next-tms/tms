class RenamePickupHoursEndToPickupHoursEndAtOnShipments < ActiveRecord::Migration[6.0]
  def change
    rename_column :shipments, :pickup_hours_end, :pickup_hours_end_at
  end
end
