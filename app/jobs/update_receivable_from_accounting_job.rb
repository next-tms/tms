class UpdateReceivableFromAccountingJob < ApplicationJob
  def perform(receivable:) = Accounting.connected? && receivable.update_from_accounting_invoice
end
