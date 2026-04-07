class AddBrokerDispatchSheetShipmentFingerprintToShipments < ActiveRecord::Migration[6.1]
  def change
    add_column :shipments, :broker_dispatch_sheet_shipment_fingerprint, :string
  end
end
