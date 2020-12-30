class AddBrokerCustomerToUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :broker_customer, foreign_key: true, default: nil
  end
end
