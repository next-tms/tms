class FetchReceivableInvoicesJob < ApplicationJob
  def perform
    Receivable.without_invoice.find_each { |receivable| FetchReceivableInvoiceJob.perform_later(receivable) }
  end
end
