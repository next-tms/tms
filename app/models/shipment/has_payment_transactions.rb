# frozen_string_literal: true

module Shipment::HasPaymentTransactions
  extend ActiveSupport::Concern

  included do
    before_save :create_payment_transaction

    def create_payment_transaction
      return unless picked_up_at_changed? && broker_carrier&.create_invoice_on_pickup? && payment_transactions.blank?

      payment_transactions.create(
        balance: total_cost,
        broker_carrier:,
        broker:,
        due_on: Date.current + broker_carrier.days_to_pay_after_invoice_date.days,
        paid: total_cost,
        pro:
      )
    end
  end
end
