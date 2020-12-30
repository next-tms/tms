class RenameDeliveryHoursStartToDeliveryHoursStartAtOnShipments < ActiveRecord::Migration[6.0]
  def change
    rename_column :shipments, :delivery_hours_start, :delivery_hours_start_at
  end
end
