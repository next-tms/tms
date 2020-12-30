class RemoveCustomerFromBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    remove_column :broker_carriers, :customer_id
  end
end
