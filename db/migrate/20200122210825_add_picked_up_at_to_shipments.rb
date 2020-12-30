class AddPickedUpAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :picked_up_at, :datetime
  end
end
