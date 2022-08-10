# frozen_string_literal: true

class RemoveWeekFromPaymentTransactions < ActiveRecord::Migration[7.0]
  def change
    remove_column :payment_transactions, :week, :integer
  end
end
