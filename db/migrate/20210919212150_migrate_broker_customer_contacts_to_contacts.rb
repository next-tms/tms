# frozen_string_litearl: true

class MigrateBrokerCustomerContactsToContacts < ActiveRecord::Migration[6.1]
  def up
    BrokerCustomerContact.find_each do |broker_customer_contact|
      broker_customer_contact.contact.update_columns(broker_customer_id: broker_customer_contact.broker_customer_id)
    end
  end

  def down; end
end
