class AddBrokerCustomerToBrokerAccessorials < ActiveRecord::Migration[6.0]
  def change
    add_reference :broker_accessorials, :broker_customer, foreign_key: true, null: true
  end
end
