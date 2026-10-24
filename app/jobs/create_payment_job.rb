class CreatePaymentJob < ApplicationJob
  def perform(broker_carrier:, payment_transaction_ids:)
    payment_transactions = broker_carrier.payment_transactions.where(id: payment_transaction_ids)

    # TODO: Enforce non-null values on payment_transactions.due_on
    due_on = payment_transactions.order(:due_on).limit(1).first.due_on
    due_on ||= DateTime.current.in_time_zone(Setting.time_zone).to_date

    Payment.create!(broker_carrier:, due_on:, payment_transactions:)
  end
end
