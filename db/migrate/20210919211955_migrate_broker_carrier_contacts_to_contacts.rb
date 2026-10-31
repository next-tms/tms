class MigrateBrokerCarrierContactsToContacts < ActiveRecord::Migration[6.1]
  def up
    BrokerCarrierContact.find_each do |broker_carrier_contact|
      broker_carrier_contact.contact.update_columns(broker_carrier_id: broker_carrier_contact.broker_carrier_id)
    end
  end

  def down; end
end
