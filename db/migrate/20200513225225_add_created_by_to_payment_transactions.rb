class AddCreatedByToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change

    add_column :payment_transactions, :created_by_id, :bigint, null: true
  
    user = User.first
    PaymentTransaction.update_all(created_by_id: user.id)
  
    add_foreign_key :payment_transactions, :users, column: :created_by_id
    change_column_null :payment_transactions, :created_by_id, false
  end
end
