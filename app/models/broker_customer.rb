# frozen_string_literal: true

class BrokerCustomer < ApplicationRecord
  belongs_to :broker
  has_many :shipments

  serialize :shipment_string_patterns, Array
  serialize :valid_freight_classes, Array

  belongs_to :primary_pickup_address, class_name: 'Address', dependent: :delete
  accepts_nested_attributes_for :primary_pickup_address, allow_destroy: true

  belongs_to :customer
  accepts_nested_attributes_for :customer

  has_many :broker_customer_sales_reps, dependent: :delete_all
  has_many :sales_reps, through: :broker_customer_sales_reps, source: 'user'
  accepts_nested_attributes_for :broker_customer_sales_reps, allow_destroy: true, reject_if: :all_blank

  has_many :broker_accessorials
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_many :broker_carriers
  accepts_nested_attributes_for :broker_carriers, allow_destroy: true, reject_if: :all_blank

  monetize :default_upcharge_cents, allow_nil: true

  has_many :upcharge_rules
  accepts_nested_attributes_for :upcharge_rules, allow_destroy: true, reject_if: :all_blank

  def eligible_broker_accessorials
    return @eligible_broker_accessorials if @eligible_broker_accessorials

    broker_customer_accessorials = broker_accessorials
    broker_accessorials = broker.broker_accessorials.where(broker_customer: nil).where.not(code: [broker_customer_accessorials.map(&:code)])

    @eligible_broker_accessorials = broker_customer_accessorials.or(broker_accessorials).order(:name)
  end

  def eligible_broker_carriers
    return @eligible_broker_carriers if @eligible_broker_carriers

    broker_customer_carriers = broker_carriers
    broker_carriers = broker.broker_carriers.where(broker_customer: nil).where.not(carrier_id: [broker_customer_carriers.map(&:id)])

    @eligible_broker_carriers = broker_customer_carriers.or(broker_carriers)
  end

  def carrier_charge_calculator(carrier_cost:, shipment:)
    return nil unless carrier_cost

    carrier_charge = Money.new(0)

    if !upcharge_rules.blank?
      carrier_charge = carrier_cost
      shipment.items.map(&:packaging).uniq.each do |packaging|
        size = shipment.items.packaging(packaging).size
        try_upcharge_rules = upcharge_rules.where('min <= ?', size).where('max >= ?', size).or(upcharge_rules.where('min <= ?', size).where(max: nil))

        if try_upcharge_rules.blank?
          return !default_upcharge.blank? && default_upcharge.positive? ? carrier_cost + default_upcharge : carrier_charge
        else
          try_upcharge_rules.each do |upcharge_rule|
            carrier_charge += upcharge_rule.upcharge * size
          end
        end
      end
    elsif !default_upcharge.blank? && default_upcharge.positive?
      carrier_charge = carrier_cost + default_upcharge
    end

    carrier_charge
  end

  def profitability_report(from_date = nil, to_date = nil)
    if from_date
      if to_date
        return nil unless to_date

        shipments = self.shipments.active.where(broker_customer: self).where('picked_up_at >= ?', from_date).where('picked_up_at <= ?', to_date)
      end
    else
      shipments = self.shipments
    end

    unless shipments.blank?
      total_cost = shipments.active.map(&:total_cost).inject(Money.new(0)) { |sum, x| sum + x }
      total_charges = shipments.active.map(&:total_charges).inject(Money.new(0)) { |sum, x| sum + x }
      total_profit = total_charges - total_cost
      total_margin = ((1 - (total_cost / total_charges)) * 100).round(1)

      {
        total_shipments: shipments.size,
        total_cost: total_cost,
        total_charges: total_charges,
        total_profit: total_profit,
        total_margin: total_margin
      }
    end
  end
end
