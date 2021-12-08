# frozen_string_literal: true

class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.find_each do |shipment|
      next unless shipment.receivables.blank?

      # TODO: Remove this
      if DateTime.current.in_time_zone('America/Los_Angeles').to_date <= Date.parse('2021-12-08') && shipment.delivered_at.in_time_zone('America/Los_Angeles').to_date < Date.parse('2021-12-01')
        next
      end

      receivable = Receivable.build_from_shipment(shipment)
      receivable.save
    end
  end
end
