class AddBrokerToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :broker_id, :bigint, null: true
  
    broker = Broker.first
    Payment.update_all(broker_id: broker.id)
  
    add_foreign_key :payments, :brokers
    change_column_null :payments, :broker_id, false
  end
end
