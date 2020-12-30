class AddWeekToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :week, :integer
  end
end
