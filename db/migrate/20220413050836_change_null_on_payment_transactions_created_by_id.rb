# frozen_string_literal: true

class ChangeNullOnPaymentTransactionsCreatedById < ActiveRecord::Migration[7.0]
  def change
    change_column_null :payment_transactions, :created_by_id, true
  end
end
