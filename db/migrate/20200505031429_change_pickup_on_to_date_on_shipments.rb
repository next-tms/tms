class ChangePickupOnToDateOnShipments < ActiveRecord::Migration[6.0]
  def change
    change_column :shipments, :pickup_on, :date
  end
end
