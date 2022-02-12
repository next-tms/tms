# frozen_string_literal: true

class CreateReceivableJob < ApplicationJob
  def perform(shipment)
    return unless shipment.receivable?

    receivable = Receivable.build_from_shipment(shipment)
    receivable.save
  
    return unless receivable.broker.automatically_authorize_receivables?
  
    receivable.update(authorized_at: DateTime.current)
  
    PushReceivableToQuickbooksJob.perform_later(receivable:) if shipment.broker.intuit_account&.connected?
  end
end
