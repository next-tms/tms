class RenameBrokerCarriersToCarrierAccounts < ActiveRecord::Migration[5.1]
  def change
    rename_table :broker_carriers, :carrier_accounts
  end
end
