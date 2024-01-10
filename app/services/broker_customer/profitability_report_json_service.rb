# frozen_string_literal: true

class BrokerCustomer::ProfitabilityReportJsonService
  attr_reader :broker_customer, :from_date, :to_date

  def initialize(broker_customer:, from_date: nil, to_date: nil)
    @broker_customer = broker_customer
    @from_date = from_date
    @to_date = to_date
  end

  def call
    return if shipments.blank?

    total_cost = shipments.active.map(&:total_cost).inject(Money.new(0)) { |sum, x| sum + x }
    total_charges = shipments.active.map(&:total_charges).inject(Money.new(0)) { |sum, x| sum + x }
    total_profit = total_charges - total_cost
    total_margin = ((1 - (total_cost / total_charges)) * 100).round(1)

    {
      total_shipments: shipments.size,
      total_cost:,
      total_charges:,
      total_profit:,
      total_margin:
    }
  end

  def shipments
    return broker_customer.shipments unless from_date.present?

    return unless to_date

    from = from_date.in_time_zone(Broker.first.time_zone).beginning_of_day
    to = to_date.in_time_zone(Broker.first.time_zone).beginning_of_day

    picked_up_at = (from..to)

    broker_customer.shipments.active.where(broker_customer:, picked_up_at:)
  end
end
