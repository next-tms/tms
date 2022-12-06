# frozen_string_literal: true

module Payment::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    after_commit :push_to_integrations

    def create_quickbooks_bill_payment
      return nil unless broker.intuit_account&.connected? && paid?

      return update_quickbooks_bill_payment unless quickbooks_bill_payment.blank?

      broker_carrier.create_quickbooks_vendor if broker_carrier.quickbooks_vendor.blank?

      result = QuickbooksAPIClient::BillPayments.new(broker:).create(self)
      return @quickbooks_bill_payment = nil if result.blank?

      update_columns(quickbooks_bill_payment_id: result.id)
      @quickbooks_bill_payment = result
    end

    def destroy_quickbooks_bill_payment
      return nil unless broker.intuit_account&.connected?

      return false if quickbooks_bill_payment.blank?

      destroyed = QuickbooksAPIClient::BillPayments.new(broker:).destroy(self)
      return false unless destroyed

      update_columns(quickbooks_bill_payment_id: nil)
      @quickbooks_bill_payment = nil
    end

    def quickbooks_bill_payment
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_bill_payment unless @quickbooks_bill_payment.blank?

      result = nil

      unless quickbooks_bill_payment_id.blank?
        result = QuickbooksAPIClient::BillPayments.new(broker:).find(quickbooks_bill_payment_id)
      end
      unless result.blank?
        persisted? ? update_columns(quickbooks_bill_payment_id: result.id) : self.quickbooks_bill_payment_id = result.id
        return @quickbooks_bill_payment = result
      end

      nil
    end

    def update_from_quickbooks_bill_payment
      if quickbooks_bill_payment.blank?
        update_columns(paid_at: nil)
        return
      end

      # Using update_columns so we can bypass the validation that recalculates amounts
      update_columns(paid_on: quickbooks_bill_payment.txn_date)

      quickbooks_bill_ids = bill_payment.line_items.map(&:linked_transactions).flatten.map { |t| t.txn_id.to_i }
      unless quickbooks_bill_ids.sort == payment_transactions.pluck(:quickbooks_bill_id).sort
        orphaned_payment_transactions = payment.payment_transactions.where.not(quickbooks_bill_id: bill_ids)

        if orphaned_payment_transactions.any?
          orphaned_payment_transactions.update_all(payment_id: nil)
          orphaned_payment_transactions.each(&:update_from_quickbooks_bill_later)
        end

        reassigned_payment_transactions = payment
                                          .broker
                                          .payment_transactions
                                          .where(
                                            id: quickbooks_bill_ids - payment_transactions.pluck(:quickbooks_bill_id)
                                          )

        if reassigned_payment_transactions.any?
          reassigned_payment_transactions.update_all(payment_id: id)
          reassigned_payment_transactions.each(&:update_from_quickbooks_bill)
        end

        missing_quickbooks_bill_ids = quickbooks_bill_ids - reassigned_payment_transactions.ids

        if missing_quickbooks_bill_ids.any?
          missing_quickbooks_bill_ids.each do |quickbooks_bill_id|
            payment_transaction = payment.broker.payment_transactions.new(quickbooks_bill_id:)
            payment_transaction.update_from_quickbooks_bill
            payment_transaction.save!
          end
        end
      end

      update_columns(balance_cents: (quickbooks_bill_payment.balance.to_f * 100).to_i)
      update_columns(paid_at: now) if quickbooks_bill_payment.balance.zero?
      update_columns(total_cents: (quickbooks_bill_payment.total.to_f * 100).to_i)

      if !sent? && (quickbooks_bill_payment.balance.zero? || quickbooks_bill_payment.email_status == 'EmailSent')
        update_columns(sent_at: now)
      end

      reload
    end

    def update_quickbooks_bill_payment
      return destroy_quickbooks_bill_payment unless paid?

      return nil unless broker.intuit_account&.connected?

      return create_quickbooks_bill_payment if quickbooks_bill_payment.blank?

      result = QuickbooksAPIClient::BillPayments.new(broker:).update(self)
      return @quickbooks_bill_payment = nil if result.blank?

      update_columns(quickbooks_bill_payment_id: result.id)
      @quickbooks_bill_payment = result
    end

    private

    def push_to_integrations
      PushPaymentToQuickbooksJob.perform_now(self) if broker.intuit_account.present?
    end
  end
end
