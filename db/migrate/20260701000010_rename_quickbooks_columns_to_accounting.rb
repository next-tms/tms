class RenameQuickbooksColumnsToAccounting < ActiveRecord::Migration[8.0]
  RESOURCE_COLUMNS = {
    banks: :account,
    broker_carriers: :vendor,
    broker_customers: :customer,
    payment_transactions: :bill,
    payments: :bill_payment,
    receivables: :invoice
  }.freeze

  def change
    RESOURCE_COLUMNS.each { |table, resource| rename_column table, :"quickbooks_#{resource}_id", :"accounting_#{resource}_id" }
  end
end
