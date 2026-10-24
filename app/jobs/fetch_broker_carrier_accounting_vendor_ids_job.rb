class FetchBrokerCarrierAccountingVendorIdsJob < ApplicationJob
  # @note Jobs enqueued before Broker removal carry a Broker GlobalID that can no longer load
  rescue_from(ActiveJob::DeserializationError) { self.class.perform_later }

  def perform
    return unless Accounting.connected?

    BrokerCarrier.where(accounting_vendor_id: nil).includes(:carrier).find_each.each(&:accounting_vendor)
  end
end
