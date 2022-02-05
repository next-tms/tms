# frozen_string_literal: true

class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.find_each do |shipment|
      receivable = Receivable.build_from_shipment(shipment)
      receivable.save

      next unless receivable.broker.automatically_authorize_receivables?

      receivable.update(authorized_at: DateTime.current)

      PushReceivableToQuickbooksJob.perform_later(receivable:) if shipment.broker.intuit_account&.connected?
    end
  end
end
