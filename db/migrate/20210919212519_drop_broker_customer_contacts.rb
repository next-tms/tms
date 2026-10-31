class DropBrokerCustomerContacts < ActiveRecord::Migration[6.1]
  def up
    drop_table :broker_customer_contacts
  end
end
