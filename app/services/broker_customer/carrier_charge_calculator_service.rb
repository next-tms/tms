# Calculate Broker Customer's Carrier Charge
class BrokerCustomer::CarrierChargeCalculatorService
  attr_reader :broker_customer, :carrier_cost, :shipment

  delegate :default_upcharge,
           :default_upcharge_percentage,
           :upcharge_rules, to: :broker_customer

  def initialize(broker_customer:, carrier_cost:, shipment:)
    @broker_customer = broker_customer
    @carrier_cost = carrier_cost
    @shipment = shipment
  end

  def call
    return if carrier_cost.blank? || carrier_cost.negative? || (default_upcharge.blank? && upcharge_rules.blank?)
    return carrier_cost + default_upcharge if upcharge_rules.blank? && default_upcharge&.positive?
    return default_pricing unless shipments_have_matching_upcharge_rule?

    carrier_charge = carrier_cost
    carrier_charge = carrier_cost + ((matched_percentage.to_f / 100) * carrier_cost) if matched_percentage

    shipment.items.each do |item|
      try_upcharge_rules = map_upcharge_rules(packaging_id: item.packaging_id, quantity: item.quantity)

      max = try_upcharge_rules.pluck(:upcharge_cents).max
      upcharge = try_upcharge_rules.where(upcharge_cents: max).first.upcharge
      carrier_charge += upcharge * item.quantity
    end

    return unless carrier_charge > carrier_cost

    carrier_charge
  end

  def map_upcharge_rules(packaging_id:, quantity:)
    upcharge_rules.where(packaging_id: packaging_id)
                  .where('min <= ?', quantity)
                  .where('max >= ?', quantity)
                  .or(
                    upcharge_rules
                    .where(packaging_id: packaging_id)
                    .where('min <= ?', quantity)
                    .where(max: nil),
                  )
  end

  def default_pricing
    return nil unless default_upcharge.positive? || default_upcharge_percentage.positive?

    carrier_charges = carrier_cost

    carrier_charges += default_upcharge if default_upcharge.positive?
    return carrier_charges unless default_upcharge_percentage.positive?

    carrier_charges += carrier_cost * (default_upcharge_percentage.to_f / 100)

    return carrier_charges
  end

  def matched_percentage
    @matched_percentage ||= begin
      upcharges = shipment.items.pluck(:packaging_id).map do |packaging_id|
        quantity = shipment.items.where(packaging_id:).sum(:quantity)
        map_upcharge_rules(packaging_id: packaging_id, quantity: quantity)
      end.flatten

      return unless upcharges.present?

      upcharges.pluck(:upcharge_percentage).max
    end
  end

  def shipments_have_matching_upcharge_rule?
    shipment.items.pluck(:packaging_id).map do |packaging_id|
      quantity = shipment.items.where(packaging_id:).sum(:quantity)
      map_upcharge_rules(packaging_id: packaging_id, quantity: quantity).present?
    end.all?(true)
  end
end


### Previous Logic

# def carrier_charge_calculator(carrier_cost:, shipment:)
#   return nil unless carrier_cost&.positive?

#   return nil if default_upcharge.blank? && upcharge_rules.blank?

#   if upcharge_rules.blank? && default_upcharge.present? && default_upcharge.positive?
#     return (carrier_cost + default_upcharge)
#   end

#   # Do all shipment.items have a matching UpchargeRule?
#   matched = true
#   matched_percentage = 0

#   packaging_ids = shipment.items.pluck(:packaging_id)
#   packaging_ids.each do |packaging_id|
#     quantity = shipment.items.where(packaging_id:).sum(:quantity)
#     try_upcharge_rules = upcharge_rules
#                          .where(packaging: packaging_id)
#                          .where('min <= ?', quantity)
#                          .where('max >= ?', quantity)
#                          .or(
#                            upcharge_rules
#                            .where(packaging: packaging_id)
#                            .where('min <= ?', quantity)
#                            .where(max: nil),
#                          )
#     if try_upcharge_rules.blank?
#       matched = false
#       break
#     else
#       upcharge_percentage = try_upcharge_rules.pluck(:upcharge_percentage).max
#       matched_percentage = upcharge_percentage if upcharge_percentage > matched_percentage
#     end
#   end

#   # Apply default default pricing
#   unless matched
#     return nil unless (matched && default_upcharge.positive?) || default_upcharge_percentage.positive?

#     carrier_charges = carrier_cost

#     carrier_charges += default_upcharge if default_upcharge.positive?
#     return carrier_charges unless default_upcharge_percentage.positive?

#     carrier_charges += carrier_cost * (default_upcharge_percentage.to_f / 100)

#     return carrier_charges
#   end

#   carrier_charge = carrier_cost

#   carrier_charge = carrier_cost + ((matched_percentage.to_f / 100) * carrier_cost) if matched_percentage

#   shipment.items.each do |item|
#     try_upcharge_rules = upcharge_rules
#                          .where(packaging: item.packaging)
#                          .where('min <= ?', item.quantity)
#                          .where('max >= ?', item.quantity)
#                          .or(
#                            upcharge_rules
#                            .where(packaging: item.packaging)
#                            .where('min <= ?', item.quantity)
#                            .where(max: nil),
#                          )

#     max = try_upcharge_rules.pluck(:upcharge_cents).max
#     upcharge = try_upcharge_rules.where(upcharge_cents: max).first.upcharge
#     carrier_charge += upcharge * item.quantity
#   end

#   carrier_charge > carrier_cost ? carrier_charge : nil
# end