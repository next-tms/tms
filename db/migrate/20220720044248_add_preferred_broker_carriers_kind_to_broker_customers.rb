class AddPreferredBrokerCarriersKindToBrokerCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :broker_customers, :preferred_broker_carriers_kind, :string
    add_index :broker_customers, :preferred_broker_carriers_kind
  end
end
