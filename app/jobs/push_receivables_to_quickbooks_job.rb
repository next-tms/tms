class PushReceivablesToQuickbooksJob < ApplicationJob
  def perform
    Receivable.authorized.not_invoiced.find_each do |receivable|
      PushReceivableToQuickbooksJob.perform_later(receivable:)
    end
  end
end
