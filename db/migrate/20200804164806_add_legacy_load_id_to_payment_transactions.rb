class AddLegacyLoadIdToPaymentTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :payment_transactions, :legacy_load_id, :string
  end
end
