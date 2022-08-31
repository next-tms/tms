# frozen_string_literal: true

class CreateReceivableJob < ApplicationJob
  discard_on ActiveRecord::RecordNotUnique

  def perform(shipment)
    Shipment.transaction do
      shipment.lock!

      return unless shipment.reload.receivable?

      receivable = Receivable.build_from_shipment(shipment)
      return if receivable.total.zero?

      receivable.save

      return unless receivable.broker.automatically_authorize_receivables?

      receivable.update(authorized_at: DateTime.current)

      PushReceivableToQuickbooksJob.perform_later(receivable:) if shipment.broker.intuit_account&.connected?
    end
  end
end
