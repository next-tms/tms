# frozen_string_literal: true

class CreateReceivableProblemsJob < ApplicationJob
  def perform
    Receivable.unpaid.find_each do |receivable|
      next unless receivable.missing_carrier_bol? || receivable.missing_carrier_pod?

      CreateReceivableProblemJob.perform_later(receivable)
    end
  end
end
