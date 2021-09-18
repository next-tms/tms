class AddBrokerBolShipmentFingerprintToShipments < ActiveRecord::Migration[6.1]
  def change
    add_column :shipments, :broker_bol_shipment_fingerprint, :string
  end
end
