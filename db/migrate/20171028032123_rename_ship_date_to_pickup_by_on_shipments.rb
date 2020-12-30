class RenameShipDateToPickupByOnShipments < ActiveRecord::Migration[5.1]
  def change
    rename_column :shipments, :ship_date, :pickup_by
  end
end
