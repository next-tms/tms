# frozen_string_literal: true

class UpdateReceivableFromQuickbooksJob < ApplicationJob
  def perform(receivable:)
    return unless receivable.shipment.broker_customer.broker.intuit_account&.connected?

    receivable.update_from_quickbooks
  end
end
