class RenamePickupByToPickupOnOnShipments < ActiveRecord::Migration[6.0]
  def change
    rename_column :shipments, :pickup_by, :pickup_on
  end
end
