class RenameLiftGateToLiftGateDeliveryOnShipments < ActiveRecord::Migration[5.1]
  def change
    rename_column :shipments, :lift_gate, :lift_gate_delivery
  end
end
