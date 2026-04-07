class CreatePaymentsJob < ApplicationJob
  def perform
    now = DateTime.current

    time_zone_names = Broker
                      .distinct
                      .pluck(:time_zone_name)
                      .select do |tz|
                        tz_now = now.in_time_zone(tz)
                        tz_now.wday.zero? && tz_now.hour >= 21 # Sunday 9 PM - 12 AM
                      end

    return false unless time_zone_names.any?

    time_zone_names.each do |time_zone_name|
      tz_now = now.in_time_zone(time_zone_name)

      Broker.where(time_zone_name:).find_each do |broker|
        broker_carriers = broker
                          .broker_carriers
                          .includes(:payment_transactions)
                          .where(
                            id: broker.payment_transactions.due.pluck(:broker_carrier_id)
                          )
        payment_date = (tz_now.end_of_week + 2.weeks).to_date

        broker_carriers.find_each do |broker_carrier|
          payment_transaction_ids = broker_carrier
                                    .payment_transactions
                                    .where(payment_id: nil)
                                    .where('due_on <= ?', payment_date)
                                    .ids

          next unless payment_transaction_ids.any?

          CreatePaymentJob.perform_later(broker_carrier:, payment_transaction_ids:)
        end
      end
    end

    true
  end
end
