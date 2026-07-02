class PushReceivablesToAccountingJob < ApplicationJob
  def perform = Receivable.authorized.not_invoiced.find_each { |receivable| PushReceivableToAccountingJob.perform_later(receivable:) }
end
