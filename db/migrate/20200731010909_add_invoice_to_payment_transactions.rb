class AddInvoiceToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :invoice, :string
  end
end
