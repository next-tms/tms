class DispatchedAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :dispatched_at, :datetime
  end
end
