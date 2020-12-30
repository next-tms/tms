class AddBrokerCustomerToBrokerCarriers < ActiveRecord::Migration[6.0]
  def change
    add_reference :broker_carriers, :broker_customer, null: false, foreign_key: true, null: true
  end
end
