class AddTrackingCarrierToShipments < ActiveRecord::Migration[6.0]
  def change
    add_reference :shipments, :tracking_carrier, foreign_key: { to_table: :carriers }
  end
end
