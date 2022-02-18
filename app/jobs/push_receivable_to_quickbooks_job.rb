# frozen_string_literal: true

class PushReceivableToQuickbooksJob < ApplicationJob
  def perform(receivable:)
    return false if receivable.shipment.picked_up_at.blank?

    receivable.update_quickbooks_invoice
    receivable.quickbooks_invoice_pdf
  end
end
