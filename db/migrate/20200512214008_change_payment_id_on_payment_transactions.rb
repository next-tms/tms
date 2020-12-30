class ChangePaymentIdOnPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:payment_transactions, :payment_id, true)
  end
end
