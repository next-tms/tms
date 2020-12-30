class AddAdditionalChargeToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :additional_charge, :boolean
  end
end
