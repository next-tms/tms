class AddBrokerBillingAddressToCarriers < ActiveRecord::Migration[6.1]
  def change
    add_reference :carriers, :broker_billing_address, foreign_key: { to_table: :addresses }, null: true
  end
end
