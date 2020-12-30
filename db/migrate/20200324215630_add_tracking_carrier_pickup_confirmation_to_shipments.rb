class AddTrackingCarrierPickupConfirmationToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :tracking_carrier_pickup_confirmation, :string
  end
end
