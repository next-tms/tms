# frozen_string_literal: true

class FetchBrokerCarrierQuickbooksVendorIdsJob < ApplicationJob
  def perform(broker:)
    return unless broker.intuit_account&.connected?

    broker_carriers = broker
                      .broker_carriers
                      .where(quickbooks_vendor_id: nil)
                      .includes(:carrier)

    broker_carriers.find_each.each(&:quickbooks_vendor)
  end
end
