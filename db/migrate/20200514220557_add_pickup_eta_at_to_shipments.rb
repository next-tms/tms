class AddPickupEtaAtToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :pickup_eta_at, :string
  end
end
