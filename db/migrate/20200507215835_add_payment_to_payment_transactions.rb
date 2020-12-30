class AddPaymentToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_reference :payment_transactions, :payment, null: false, foreign_key: true
  end
end
