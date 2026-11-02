class AddDSDCToPaymentTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column(:payment_transactions, :dsdc_invoice, :jsonb)
    add_column(:payment_transactions, :dsdc_unique_id, :string)
    add_index(
      :payment_transactions,
      %i[broker_carrier_id dsdc_unique_id],
      name: 'index_payment_transactions_on_dsdc_unique_id',
      unique: true
    )
  end
end
