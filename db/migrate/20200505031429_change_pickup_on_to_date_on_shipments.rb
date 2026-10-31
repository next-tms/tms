class ChangePickupOnToDateOnShipments < ActiveRecord::Migration[6.0]
  def up
    change_column :shipments, :pickup_on, :date
  end
end
