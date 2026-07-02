class UpdateReceivablesFromAccountingJob < ApplicationJob
  def perform
    return false unless Accounting.connected?

    Receivable.unpaid.or(Receivable.unsent).distinct.find_each { |receivable| UpdateReceivableFromAccountingJob.perform_later(receivable:) }
  end
end
