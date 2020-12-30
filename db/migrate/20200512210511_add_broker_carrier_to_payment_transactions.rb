class AddBrokerCarrierToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_reference :payment_transactions, :broker_carrier, null: true, foreign_key: true
  end
end
