module PaymentTransaction::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    after_commit :push_to_quickbooks

    def create_quickbooks_bill
      return nil unless broker.intuit_account&.connected?

      return update_quickbooks_bill unless quickbooks_bill.blank?

      return broker_carrier.create_quickbooks_vendor if broker_carrier.quickbooks_vendor.blank?

      result = QuickbooksAPIClient::Bills.new(broker:).create(self)
      return @quickbooks_bill = nil if result.blank?

      update_columns(quickbooks_bill_id: result.id)
      @quickbooks_bill = result
    end

    def quickbooks_bill
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_bill unless @quickbooks_bill.blank?

      result = nil

      result = QuickbooksAPIClient::Bills.new(broker:).find(quickbooks_bill_id) unless quickbooks_bill_id.blank?
      unless result.blank?
        persisted? ? update_columns(quickbooks_bill_id: result.id) : self.quickbooks_bill_id = result.id
        return @quickbooks_bill = result
      end

      result = QuickbooksAPIClient::Bills.new(broker:).find_by_doc_number(shipment.load_id)
      unless result.blank?
        persisted? ? update_columns(quickbooks_bill_id: result.id) : self.quickbooks_bill_id = result.id
        return @quickbooks_bill = result
      end

      nil
    end

    def update_from_quickbooks_bill
      return if quickbooks_bill.blank?

      method = persisted? ? :update_columns : :assign_attributes

      # Using update_columns so we can bypass the validation that recalculates amounts
      send(
        method,
        balance_cents: (quickbooks_bill.balance.to_f * 100).to_i,
        total_cents: (quickbooks_bill.total.to_f * 100).to_i
      )

      now = DateTime.current
      send(method, paid_at: now) if quickbooks_bill.balance.zero?

      reload if persisted?
    end

    def update_from_quickbooks_bill_later
      FetchPaymentTransactionQuickbooksBillJob.perform_later(self)
    end

    def update_quickbooks_bill
      return nil unless broker.intuit_account&.connected?

      return create_quickbooks_bill if quickbooks_bill.blank?

      result = QuickbooksAPIClient::Bills.new(broker:).update(self)
      return @quickbooks_bill = nil if result.blank?

      update_columns(quickbooks_bill_id: result.id)
      @quickbooks_bill = result
    end

    private

    def push_to_quickbooks
      PushPaymentTransactionToQuickbooksJob.perform_later(self) if broker.intuit_account.present?
    end
  end
end
