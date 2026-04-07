class AddBrokerToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :broker_id, :bigint, null: true

    broker = Broker.first
    PaymentTransaction.update_all(broker_id: broker.id)

    add_foreign_key :payment_transactions, :brokers
    change_column_null :payment_transactions, :broker_id, false
  end
end
