class AddCanceledAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :canceled_at, :datetime
  end
end
