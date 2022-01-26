# frozen_string_literal: true

class AddQuickbooksInvoiceIdToReceivables < ActiveRecord::Migration[7.0]
  def change
    add_column :receivables, :quickbooks_invoice_id, :string, index: true
  end
end
