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
  class << self
    def companyable_order
      joins(:customer).order('customers.name')
    end
  end

  include ::Instigatable
  include BrokerCustomer::Instigatable
  include BrokerCustomer::QuickbooksSyncable
  include Companyable

  after_commit :problematic_shipments_later

  before_update :update_quickbooks_invoices, if: :receivables_contact_id_changed?
  before_validation :set_receivables_contact_companyable, if: -> { receivables_contact&.new_record? }

  audited

  belongs_to :broker

  belongs_to :office_address, class_name: 'Address', dependent: :destroy
  accepts_nested_attributes_for :office_address, allow_destroy: true

  belongs_to :primary_pickup_address, class_name: 'Address', dependent: :destroy
  accepts_nested_attributes_for :primary_pickup_address, allow_destroy: true

  belongs_to :customer
  accepts_nested_attributes_for :customer

  delegate :name, to: :customer

  belongs_to :receivables_contact, class_name: 'Contact', dependent: :destroy
  accepts_nested_attributes_for :receivables_contact, allow_destroy: false

  enum preferred_broker_carriers_kind: { blacklist: 'blacklist', whitelist: 'whitelist' }

  has_many :broker_customer_sales_reps, dependent: :destroy
  has_many :sales_reps, through: :broker_customer_sales_reps, source: 'user'
  accepts_nested_attributes_for :broker_customer_sales_reps, allow_destroy: true, reject_if: :all_blank

  has_many :broker_customer_dispatchers, dependent: :destroy
  has_many :dispatchers, through: :broker_customer_dispatchers, source: 'user'
  accepts_nested_attributes_for :broker_customer_dispatchers, allow_destroy: true, reject_if: :all_blank

  has_many :broker_accessorials, dependent: :destroy
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  has_many :broker_carriers, dependent: :destroy
  accepts_nested_attributes_for :broker_carriers, allow_destroy: true, reject_if: :all_blank

  has_many :document_preferences, dependent: :destroy
  accepts_nested_attributes_for :document_preferences, allow_destroy: true, reject_if: :all_blank

  has_many :preferred_broker_carriers, class_name: 'PreferredBrokerCarrier'
  accepts_nested_attributes_for :preferred_broker_carriers, allow_destroy: true, reject_if: :all_blank

  has_many :receivables, dependent: :nullify
  has_many :shipments, dependent: :nullify

  has_many :receivables, through: :shipments

  has_many :upcharge_rules
  accepts_nested_attributes_for :upcharge_rules, allow_destroy: true, reject_if: :all_blank

  has_many :users, as: :companyable, dependent: :destroy

  enum receivables_schedule: {
    daily: 'daily',
    immediately: 'immediately',
    monthly: 'monthly',
    never: 'never',
    weekly: 'weekly'
  }

  monetize :default_upcharge_cents, allow_nil: true

  serialize :shipment_string_patterns, Array
  serialize :valid_freight_classes, Array

  validate :check_pricing_rules

  def eligible_broker_accessorials
    return @eligible_broker_accessorials if @eligible_broker_accessorials

    broker_customer_accessorials = broker_accessorials
    broker_accessorials = broker
                          .broker_accessorials
                          .where(broker_customer: nil)
                          .where
                          .not(code: [broker_customer_accessorials.map(&:code)])

    @eligible_broker_accessorials = broker_customer_accessorials.or(broker_accessorials).order(:name)
  end

  # @return [BrokerCarrier::ActiveRecord_Relation]
  def eligible_broker_carriers(user_type: :customer)
    @eligible_broker_carriers ||= {}
    return @eligible_broker_carriers[user_type] if @eligible_broker_carriers[user_type].present?

    scope = if user_type == :broker
              broker.broker_carriers
            else
              case preferred_broker_carriers_kind
              when nil then broker.broker_carriers
              when 'whitelist'
                BrokerCarrier.where(id: preferred_broker_carriers.pluck(:broker_carrier_id))
              when 'blacklist'
                broker.broker_carriers.where.not(id: preferred_broker_carriers.pluck(:broker_carrier_id))
              end
            end

    @eligible_broker_carriers[user_type] = scope.where(broker_customer: [nil, self])
  end

  def carrier_charge_calculator(carrier_cost:, shipment:)
    return nil unless carrier_cost&.positive?

    return nil if default_upcharge.blank? && upcharge_rules.blank?

    if upcharge_rules.blank? && default_upcharge.present? && default_upcharge.positive?
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
                             .where(max: nil),
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
    return nil unless (matched && default_upcharge.positive?) || default_upcharge_percentage.positive?

    carrier_charges = carrier_cost

    carrier_charges += default_upcharge if default_upcharge.positive?
    return carrier_charges unless default_upcharge_percentage.positive?

    carrier_charges += carrier_cost * (default_upcharge_percentage.to_f / 100)

    return carrier_charges

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
                             .where(max: nil),
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
          picked_up_at: (from_date.beginning_of_day..to_date.end_of_day),
        )
      end
    else
      shipments = self.shipments
    end

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

  def create_quickbooks_customer
    return false unless broker.intuit_account&.connected?

    return update_quickbooks_customer if quickbooks_customer.present?

    result = QuickbooksAPIClient::Customers.new(broker:).create(self)
    return false if result.blank?

    update!(quickbooks_customer_id: result.id)
    @quickbooks_customer = result

    true
  end

  def update_quickbooks_customer
    return false unless broker.intuit_account&.connected?

    if quickbooks_customer_id.blank? && quickbooks_customer.present?
      update!(quickbooks_customer_id: quickbooks_customer.id)
    end

    return create_quickbooks_customer if quickbooks_customer.blank?

    result = QuickbooksAPIClient::Customers.new(broker:).update(self)
    return false if result.blank?

    @quickbooks_customer = result

    true
  end

  def quickbooks_customer
    return nil unless broker.intuit_account&.connected?
    return @quickbooks_customer if @quickbooks_customer.present?

    result = nil

    if quickbooks_customer_id.present?
      result = QuickbooksAPIClient::Customers.new(broker:).find(quickbooks_customer_id)
    end
    return @quickbooks_customer = result if result.present?

    customers = QuickbooksAPIClient::Customers.new(broker:)
    result = customers.find_by_name(customer.name) # rubocop:disable Rails/DynamicFindBy
    return nil if result.blank?

    update_columns(quickbooks_customer_id: result.id)
    @quickbooks_customer = result
  end

  def to_quickbooks_customer
    Quickbooks::Model::Customer.new(
      billing_address: office_address.to_quickbooks_physical_address,
      company_name: customer.name,
      display_name: customer.name,
      shipping_address: primary_pickup_address&.to_quickbooks_physical_address,
    )
  end

  def update_quickbooks_invoices
    return unless receivables.unpaid.present?

    receivables.unpaid.each { |receivable| receivable.update_quickbooks_invoice }
  end

  private

  def check_pricing_rules
    return unless can_quote?

    if (default_upcharge_cents.blank? || default_upcharge_cents.zero?) &&
       (default_upcharge_percentage.blank? || default_upcharge_percentage.zero?) &&
       upcharge_rules.blank?
      errors.add(:can_quote, 'cannot be enabled without fallback pricing rule')
    end
  end

  def problematic_shipments_later
    ids = Problem.unresolved.where(resolvable: shipments).pluck(&:resolvable_id)
    ProblematicJob.perform_later(ids, type: 'Shipment')
  end

  def set_receivables_contact_companyable
    receivables_contact.assign_attributes(companyable: self)
  end
end
