class PushReceivableToAccountingJob < ApplicationJob
  def perform(receivable:)
    return false if receivable.shipment.picked_up_at.blank?

    receivable.update_accounting_invoice
    receivable.accounting_invoice_pdf
    receivable.save # to save invoice PDF
  end
end
