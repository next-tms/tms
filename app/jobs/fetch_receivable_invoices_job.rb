# frozen_string_literal: true

class FetchReceivableInvoicesJob < ApplicationJob
  def perform
    Receivable.without_invoice.find_each do |receivable|
      FetchReceivableInvoiceJob.perform_later(receivable)
    end
  end
end
