# frozen_string_literal: true

class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.find_each do |shipment|
      next unless shipment.receivables.blank?

      # Feature first implemented
      next if shipment.picked_up_at.in_time_zone('America/Los_Angeles').to_date < Date.parse('2021-12-01')

      receivable = Receivable.build_from_shipment(shipment)
      receivable.save
    end
  end
end
