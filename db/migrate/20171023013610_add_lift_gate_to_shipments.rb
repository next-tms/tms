class AddLiftGateToShipments < ActiveRecord::Migration[5.1]
  def change
    add_column :shipments, :lift_gate, :boolean
  end
end
