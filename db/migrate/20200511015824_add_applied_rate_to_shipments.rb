class AddAppliedRateToShipments < ActiveRecord::Migration[6.0]
  def change
    add_reference :shipments, :applied_rate, null: true, foreign_key: { to_table: :rates }
  end
end
