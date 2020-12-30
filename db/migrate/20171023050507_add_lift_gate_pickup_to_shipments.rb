class AddLiftGatePickupToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :lift_gate_pickup, :boolean
  end
end
