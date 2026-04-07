class AddBrokerLabelShipmentFingerprintToShipments < ActiveRecord::Migration[7.1]
  def change
    add_column(:shipments, :broker_label_shipment_fingerprint, :string)
  end
end
