class AddBrokerCarrierToContacts < ActiveRecord::Migration[6.1]
  def change
    add_reference :contacts, :broker_carrier, null: true, foreign_key: true
  end
end
