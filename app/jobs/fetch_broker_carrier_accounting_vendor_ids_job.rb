class FetchBrokerCarrierAccountingVendorIdsJob < ApplicationJob
  def perform(broker:)
    return unless Accounting.connected?

    broker_carriers = broker
                      .broker_carriers
                      .where(accounting_vendor_id: nil)
                      .includes(:carrier)

    broker_carriers.find_each.each(&:accounting_vendor)
  end
end
