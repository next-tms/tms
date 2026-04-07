class AddQuickbooksInvoiceIdToReceivables < ActiveRecord::Migration[7.0]
  def change
    add_column :receivables, :quickbooks_invoice_id, :string
add_index :receivables, :quickbooks_invoice_id
  end
end
