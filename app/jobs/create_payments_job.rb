# frozen_string_literal: true

class CreatePaymentsJob < ApplicationJob
  def perform(broker_carrier)
    payment_date = (DateTime.current.in_time_zone(broker_carrier.broker.time_zone).end_of_week + 1.week).to_date

    payment_transactions = broker_carrier
                           .payment_transactions
                           .where(payment: nil)
                           .where('due_on <= ?', payment_date)

    return if payment_transactions.blank?

    CreatePaymentJob.perform_later(broker_carrier:, payment_transactions:)
  end
end
