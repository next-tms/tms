# frozen_string_literal: true

# == Schema Information
#
# Table name: broker_customers
#
# @!attribute id
#   @return []
# @!attribute always_show_quotes_based_on_calculated_classes
#   @return [Boolean]
# @!attribute can_quote
#   @return [Boolean]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute default_upcharge_cents
#   @return [Integer]
# @!attribute default_upcharge_currency
#   @return [String]
# @!attribute default_upcharge_percentage
#   @return [Float]
# @!attribute enable_auto_freight_class
#   @return [Boolean]
# @!attribute ignore_value_on_api_quotes
#   @return [Boolean]
# @!attribute internal_notes
#   @return [String]
# @!attribute requires_carrier_bol_on_receivables
#   @return [Boolean]
# @!attribute requires_carrier_pod_on_receivables
#   @return [Boolean]
# @!attribute shipment_string_patterns
#   @return [String]
# @!attribute valid_freight_classes
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_id
#   @return []
# @!attribute customer_id
#   @return []
# @!attribute office_address_id
#   @return []
# @!attribute primary_pickup_address_id
#   @return []
# @!attribute quickbooks_customer_id
#   @return [String]
# @!attribute receivables_contact_id
#   @return []
#
# Indexes
#
#  index_broker_customers_on_broker_id                            (broker_id)
#  index_broker_customers_on_customer_id                          (customer_id)
#  index_broker_customers_on_office_address_id                    (office_address_id)
#  index_broker_customers_on_primary_pickup_address_id            (primary_pickup_address_id)
#  index_broker_customers_on_receivables_contact_id               (receivables_contact_id)
#  index_broker_customers_on_requires_carrier_bol_on_receivables  (requires_carrier_bol_on_receivables)
#  index_broker_customers_on_requires_carrier_pod_on_receivables  (requires_carrier_pod_on_receivables)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (office_address_id => addresses.id)
#  fk_rails_...  (primary_pickup_address_id => addresses.id)
#  fk_rails_...  (receivables_contact_id => contacts.id)
#
class BrokerCustomer < ApplicationRecord
  belongs_to :broker

  belongs_to :office_address, class_name: 'Address', dependent: :delete
  accepts_nested_attributes_for :office_address, allow_destroy: true

  belongs_to :primary_pickup_address, class_name: 'Address', dependent: :delete
  accepts_nested_attributes_for :primary_pickup_address, allow_destroy: true

  belongs_to :customer
  accepts_nested_attributes_for :customer

  belongs_to :receivables_contact, class_name: 'Contact'
  accepts_nested_attributes_for :receivables_contact, allow_destroy: false

  has_many :contacts

  has_many :broker_customer_sales_reps, dependent: :destroy
  has_many :sales_reps, through: :broker_customer_sales_reps, source: 'user'
  accepts_nested_attributes_for :broker_customer_sales_reps, allow_destroy: true, reject_if: :all_blank

  has_many :broker_accessorials
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_many :broker_carriers
  accepts_nested_attributes_for :broker_carriers, allow_destroy: true, reject_if: :all_blank

  has_many :document_preferences
  accepts_nested_attributes_for :document_preferences, allow_destroy: true, reject_if: :all_blank

  has_many :receivables
  has_many :shipments

  has_many :receivables, through: :shipments

  has_many :upcharge_rules
  accepts_nested_attributes_for :upcharge_rules, allow_destroy: true, reject_if: :all_blank

  enum receivables_schedule: { daily: 'daily', picked_up: 'picked_up', weekly: 'weekly', monthly: 'monthly' }

  monetize :default_upcharge_cents, allow_nil: true

  serialize :shipment_string_patterns, Array
  serialize :valid_freight_classes, Array

  validate :check_pricing_rules

  def eligible_broker_accessorials
    return @eligible_broker_accessorials if @eligible_broker_accessorials

    broker_customer_accessorials = broker_accessorials
    broker_accessorials = broker.broker_accessorials.where(broker_customer: nil).where.not(code: [broker_customer_accessorials.map(&:code)])

    @eligible_broker_accessorials = broker_customer_accessorials.or(broker_accessorials).order(:name)
  end

  def eligible_broker_carriers
    return @eligible_broker_carriers if @eligible_broker_carriers

    broker_customer_carriers = broker_carriers
    broker_carriers = broker.broker_carriers.where(broker_customer: nil).where.not(carrier_id: broker_customer_carriers.pluck(:carrier_id))

    @eligible_broker_carriers = broker_customer_carriers.or(broker_carriers)
  end

  def carrier_charge_calculator(carrier_cost:, shipment:)
    return nil unless carrier_cost&.positive?

    return nil if default_upcharge.blank? && upcharge_rules.blank?

    if upcharge_rules.blank? && !default_upcharge.blank? && default_upcharge.positive?
      return (carrier_cost + default_upcharge)
    end

    # Do all shipment.items have a matching UpchargeRule?
    matched = true
    matched_percentage = 0

    packaging_ids = shipment.items.pluck(:packaging_id)
    packaging_ids.each do |packaging_id|
      quantity = shipment.items.where(packaging_id:).sum(:quantity)
      try_upcharge_rules = upcharge_rules
                           .where(packaging: packaging_id)
                           .where('min <= ?', quantity)
                           .where('max >= ?', quantity)
                           .or(
                             upcharge_rules
                             .where(packaging: packaging_id)
                             .where('min <= ?', quantity)
                             .where(max: nil)
                           )
      if try_upcharge_rules.blank?
        matched = false
        break
      else
        upcharge_percentage = try_upcharge_rules.pluck(:upcharge_percentage).max
        matched_percentage = upcharge_percentage if upcharge_percentage > matched_percentage
      end
    end

    # Apply default default pricing
    unless matched
      if default_upcharge.positive? || default_upcharge_percentage.positive?
        carrier_charges = carrier_cost

        carrier_charges += default_upcharge if default_upcharge.positive?
        return carrier_charges unless default_upcharge_percentage.positive?

        carrier_charges += carrier_cost * (default_upcharge_percentage.to_f / 100)

        return carrier_charges
      else
        return nil
      end
    end

    carrier_charge = carrier_cost

    carrier_charge = carrier_cost + ((matched_percentage.to_f / 100) * carrier_cost) if matched_percentage

    shipment.items.each do |item|
      try_upcharge_rules = upcharge_rules
                           .where(packaging: item.packaging)
                           .where('min <= ?', item.quantity)
                           .where('max >= ?', item.quantity)
                           .or(
                             upcharge_rules
                             .where(packaging: item.packaging)
                             .where('min <= ?', item.quantity)
                             .where(max: nil)
                           )

      max = try_upcharge_rules.pluck(:upcharge_cents).max
      upcharge = try_upcharge_rules.where(upcharge_cents: max).first.upcharge
      carrier_charge += upcharge * item.quantity
    end

    carrier_charge > carrier_cost ? carrier_charge : nil
  end

  def profitability_report(from_date = nil, to_date = nil)
    if from_date
      if to_date
        return nil unless to_date

        shipments = self.shipments.active.where(broker_customer: self).where(
          picked_up_at: (from_date.beginning_of_day..to_date.end_of_day)
        )
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
        total_cost:,
        total_charges:,
        total_profit:,
        total_margin:
      }
    end
  end

  def create_quickbooks_customer
    return nil unless broker.intuit_account&.connected?

    result = quickbooks_customer
    return result unless result.blank?

    result = QuickbooksApiClient::Customers.new(broker:).create(self)
    return nil if result.blank?

    update_columns(quickbooks_customer_id: result.id)
    @quickbooks_customer = result
  end

  def update_quickbooks_customer
    return nil unless broker.intuit_account&.connected?

    result = QuickbooksApiClient::Customers.new(broker:).update(self)
    return nil if result.blank?

    @quickbooks_customer = result
  end

  def quickbooks_customer
    return nil unless broker.intuit_account&.connected?
    return @quickbooks_customer unless @quickbooks_customer.blank?

    result = nil

    unless quickbooks_customer_id.blank?
      result = QuickbooksApiClient::Customers.new(broker:).find(quickbooks_customer_id)
    end
    return @quickbooks_customer = result unless result.blank?

    result = QuickbooksApiClient::Customers.new(broker:).find_by_name(customer.name)
    return nil if result.blank?

    update_columns(quickbooks_customer_id: result.id)
    @quickbooks_customer = result
  end

  def to_quickbooks_customer
    Quickbooks::Model::Customer.new(
      billing_address: office_address.to_quickbooks_physical_address,
      company_name: customer.name,
      display_name: customer.name,
      shipping_address: primary_pickup_address&.to_quickbooks_physical_address
    )
  end

  private

  def check_pricing_rules
    return unless can_quote?

    if (default_upcharge_cents.blank? || default_upcharge_cents.zero?) && (default_upcharge_percentage.blank? || default_upcharge_percentage.zero?) && upcharge_rules.blank?
      errors.add(:base, 'Fallback pricing rules must exist to enable customer quoting.')
    end
  end
end
