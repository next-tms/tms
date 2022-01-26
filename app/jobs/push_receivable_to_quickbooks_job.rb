# frozen_string_literal: true

class PushReceivableToQuickbooksJob < ApplicationJob
  def perform(receivable:)
    receivable.update_quickbooks_invoice
  end
end
