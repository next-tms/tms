# frozen_string_literal: true

class UpdateReceivablesFromQuickbooksJob < ApplicationJob
  def perform
    IntuitAccount.all.find_each do |intuit_account|
      next unless intuit_account&.connected?

      intuit_account.broker.receivables.unpaid.find_each do |receivable|
        UpdateReceivableFromQuickbooksJob.perform_later(receivable)
      end
    end
  end
end
