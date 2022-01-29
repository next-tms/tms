# frozen_string_literal: true

class FetchReceivableInvoices < ApplicationJob
  def perform
    Receivable.without_invoice.find_each do |receivable|
      FetchReceivableInvoice.perform_later(receivable)
    end
  end
end
