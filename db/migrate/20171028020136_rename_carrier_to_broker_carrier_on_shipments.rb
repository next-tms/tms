class RenameCarrierToBrokerCarrierOnShipments < ActiveRecord::Migration[5.1]
  def change
    rename_column :shipments, :carrier_id, :broker_carrier_id
  end
end
