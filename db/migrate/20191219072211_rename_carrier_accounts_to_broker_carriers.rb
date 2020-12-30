class RenameCarrierAccountsToBrokerCarriers < ActiveRecord::Migration[5.2]
  def change
    rename_table :carrier_accounts, :broker_carriers
  end
end
