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
    return if dispatched_shipments.empty?

    total_cost = dispatched_shipments.map(&:total_cost).inject(Money.new(0)) { |sum, x| sum + x }
    total_charges = dispatched_shipments.map(&:total_charges).inject(Money.new(0)) { |sum, x| sum + x }
    total_profit = total_charges - total_cost
    total_margin = ((1 - (total_cost / total_charges)) * 100).round(1)

    {
      dispatched_shipments_count: dispatched_shipments.size,
      quoted_shipments_count: quoted_shipments.size,
      total_charges:,
      total_cost:,
      total_margin:,
      total_profit:,
      total_shipments_count: (dispatched_shipments + quoted_shipments).size
    }
  end

  private

  def dispatched_shipments
    @dispatched_shipments ||= broker_customer.shipments.active.where(picked_up_at: from..to)
  end

  def quoted_shipments
    @quoted_shipments ||= broker_customer.shipments.pending_dispatch.where(created_at: from..to)
  end

  def tz
    @tz ||= ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name))
  end
end
