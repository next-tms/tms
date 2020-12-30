class RenameBrokerCarrierOnShipments < ActiveRecord::Migration[5.1]
  def change
    rename_column :shipments, :broker_carrier_id, :carrier_account_id
  end
end
