class ChangePickupByToDateTimeOnShipments < ActiveRecord::Migration[6.0]
  def up
    change_column :shipments, :pickup_by, :datetime
  end

  def down
    change_column :shipments, :pickup_by, :date
  end
end
