# frozen_string_literal: true

class FetchReceivableInvoice < ApplicationJob
  def perform(receivable)
    receivable.fetch_invoice
  end
end
