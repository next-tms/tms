class AddTrackingCarrierProToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :shipments, :tracking_carrier_pro, :string
  end
end
