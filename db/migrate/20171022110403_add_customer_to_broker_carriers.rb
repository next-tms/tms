class AddCustomerToBrokerCarriers < ActiveRecord::Migration[5.1]
  def change
    add_reference :broker_carriers, :customer, foreign_key: true
  end
end
