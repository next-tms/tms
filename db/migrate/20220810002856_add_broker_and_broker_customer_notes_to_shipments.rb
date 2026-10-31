class AddBrokerAndBrokerCustomerNotesToShipments < ActiveRecord::Migration[7.0]
  def change
    add_column :shipments, :broker_and_broker_customer_notes, :text
    add_index :shipments, :broker_and_broker_customer_notes
  end
end
