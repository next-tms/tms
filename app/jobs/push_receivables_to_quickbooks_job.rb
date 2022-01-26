# frozen_string_literal: true

class PushReceivablesToQuickbooksJob < ApplicationJob
  def perform(broker:)
    broker.receivables.authorized.not_invoiced.find_each do |receivable|
      PushReceivableToQuickbooksJob.perform_later(receivable:)
    end
  end
end
