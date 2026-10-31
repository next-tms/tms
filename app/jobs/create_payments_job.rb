class CreatePaymentsJob < ApplicationJob
  def perform
    now = DateTime.current.in_time_zone(Setting.time_zone)
    return unless now.wday.zero? && now.hour >= 21 # Sunday 9 PM - 12 AM

    broker_carriers = BrokerCarrier.includes(:payment_transactions).where(id: PaymentTransaction.due.select(:broker_carrier_id))
    payment_date = (now.end_of_week + 2.weeks).to_date

    broker_carriers.find_each do |broker_carrier|
      payment_transaction_ids = broker_carrier.payment_transactions.where(payment_id: nil).where(due_on: ..payment_date).ids

      next unless payment_transaction_ids.any?

      CreatePaymentJob.perform_later(broker_carrier:, payment_transaction_ids:)
    end
  end
end
