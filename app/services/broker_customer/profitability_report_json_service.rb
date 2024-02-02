# frozen_string_literal: true

class BrokerCustomer::ProfitabilityReportJsonService
  attr_reader :broker_customer, :from, :to

  def initialize(broker_customer:, from_date: nil, to_date: nil)
    raise ArgumentError, 'broker_customer must be a BrokerCustomer' unless broker_customer.is_a?(BrokerCustomer)
    raise ArgumentError, 'from_date must be a Date' unless from_date.is_a?(Date)
    raise ArgumentError, 'to_date must be a Date' unless to_date.is_a?(Date)

    @broker_customer = broker_customer
    @from = from_date.in_time_zone(tz).beginning_of_day
    @to = to_date.in_time_zone(tz).end_of_day
  end

  def call
    return if shipments.empty?

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

  private

  def shipments
    return broker_customer.shipments if from.blank?

    return unless to

    picked_up_at = (from..to)

    broker_customer.shipments.active.where(broker_customer:, picked_up_at:)
  end

  def tz
    @tz ||= ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name))
  end
end
