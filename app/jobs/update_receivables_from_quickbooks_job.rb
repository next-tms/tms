# frozen_string_literal: true

class UpdateReceivablesFromQuickbooksJob < ApplicationJob
  def perform
    IntuitAccount.all.find_each do |intuit_account|
      next unless intuit_account&.connected?

      receivables = intuit_account.broker.receivables.unpaid.or(intuit_account.broker.receivables.unsent).distinct

      receivables.find_each do |receivable|
        UpdateReceivableFromQuickbooksJob.perform_later(receivable:)
      end
    end
  end
end
