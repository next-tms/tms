# frozen_string_literal: true

class CreateReceivableProblemsJob < ApplicationJob
  def perform
    Receivable.unpaid.find_each do |receivable|
      next unless receivable.missing_carrier_bol? || receivable.missing_carrier_pod?
      next if receivable.missing_carrier_bol? && !receivable.shipment.picked_up?
      next if receivable.missing_carrier_pod? && !receivable.shipment.delivered?

      CreateReceivableProblemJob.perform_later(receivable)
    end
  end
end
