class RenameCarrierAccountIdOnShipmentsToBrokerCarrierId < ActiveRecord::Migration[5.2]
  def change
    rename_column :shipments, :carrier_account_id, :broker_carrier_id
  end
end
