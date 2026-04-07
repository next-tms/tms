class DropBrokerCarrierContacts < ActiveRecord::Migration[6.1]
  def change
    drop_table :broker_carrier_contacts
  end
end
