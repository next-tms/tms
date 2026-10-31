class DropBrokerCarrierContacts < ActiveRecord::Migration[6.1]
  def up
    drop_table :broker_carrier_contacts
  end
end
