class DropBrokerCustomerContacts < ActiveRecord::Migration[6.1]
  def change
    drop_table :broker_customer_contacts
  end
end
