# Create JSON for ProfitabilityReport of Broker Customer
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
    if from_date
      return unless to_date

      broker_customer.shipments.active.where(broker_customer: broker_customer).where(
        picked_up_at: (from_date.beginning_of_day..to_date.end_of_day)
      )
    else
      broker_customer.shipments
    end
  end
end


### Previous Logic

# if from_date
#   if to_date
#     return nil unless to_date

#     shipments = self.shipments.active.where(broker_customer: self).where(
#       picked_up_at: (from_date.beginning_of_day..to_date.end_of_day),
#     )
#   end
# else
#   shipments = self.shipments
# end

# return if shipments.blank?

# total_cost = shipments.active.map(&:total_cost).inject(Money.new(0)) { |sum, x| sum + x }
# total_charges = shipments.active.map(&:total_charges).inject(Money.new(0)) { |sum, x| sum + x }
# total_profit = total_charges - total_cost
# total_margin = ((1 - (total_cost / total_charges)) * 100).round(1)

# {
#   total_shipments: shipments.size,
#   total_cost:,
#   total_charges:,
#   total_profit:,
#   total_margin:
# }