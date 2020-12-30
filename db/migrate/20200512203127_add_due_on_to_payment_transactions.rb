class AddDueOnToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :due_on, :date
  end
end
