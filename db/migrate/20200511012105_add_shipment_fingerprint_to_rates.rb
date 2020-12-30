class AddShipmentFingerprintToRates < ActiveRecord::Migration[6.0]
  def change
    add_column :rates, :shipment_fingerprint, :string
  end
end
