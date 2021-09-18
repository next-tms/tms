class AddBrokerQuoteShipmentFingerprintToShipments < ActiveRecord::Migration[6.1]
  def change
    add_column :shipments, :broker_quote_shipment_fingerprint, :string
  end
end
