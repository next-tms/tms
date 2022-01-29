# frozen_string_literal: true

class FetchReceivableInvoiceJob < ApplicationJob
  def perform(receivable)
    receivable.fetch_invoice
  end
end
