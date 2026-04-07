class AddBrokerCustomerToContacts < ActiveRecord::Migration[6.1]
  def change
    add_reference :contacts, :broker_customer, null: true, foreign_key: true
  end
end
