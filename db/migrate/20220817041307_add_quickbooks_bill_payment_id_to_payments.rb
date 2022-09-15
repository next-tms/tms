# frozen_string_literal: true

class AddQuickbooksBillPaymentIdToPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :payments, :quickbooks_bill_payment_id, :integer, index: true
  end
end
