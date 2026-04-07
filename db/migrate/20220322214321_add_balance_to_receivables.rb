class AddBalanceToReceivables < ActiveRecord::Migration[7.0]
  def up
    add_monetize :receivables, :balance, index: true

    Receivable.find_each do |receivable|
      unless receivable.paid_at.blank?
        receivable.update_columns(balance_cents: 0, balance_currency: receivable.total_currency)
        next
      end

      # We'll correct these values later in a background job
      receivable.update_columns(
        balance_cents: receivable.total_cents,
        balance_currency: receivable.total_currency
      )
    end
  end

  def down
    remove_column :receivables, :balance_cents
    remove_column :receivables, :balance_currency
  end
end
