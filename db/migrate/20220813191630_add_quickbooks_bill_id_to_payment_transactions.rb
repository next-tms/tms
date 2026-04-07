class AddQuickbooksBillIdToPaymentTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_transactions, :quickbooks_bill_id, :integer
add_index :payment_transactions, :quickbooks_bill_id
  end
end
