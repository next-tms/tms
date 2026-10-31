class RemoveDocumentFingerprintsFromShipments < ActiveRecord::Migration[7.1]
  def up
    change_table(:shipments, bulk: true) do |t|
      t.remove(
        :broker_bol_shipment_fingerprint,
        :broker_dispatch_sheet_shipment_fingerprint,
        :broker_label_shipment_fingerprint,
        :broker_quote_shipment_fingerprint
      )
    end
  end
end
