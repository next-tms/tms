class RenameDeliveryHoursEndToDeliveryHoursEndAtOnShipments < ActiveRecord::Migration[6.0]
  def change
    rename_column :shipments, :delivery_hours_end, :delivery_hours_end_at
  end
end
