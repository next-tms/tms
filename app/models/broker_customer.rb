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
  def eligible_broker_carriers(user_type = :customer)
    scope = BrokerCarrier.where(broker_customer: [nil, self])

    # @note Always prefer customer-sepcific accounts
    if broker_carriers.any?
      scope = scope
              .where
              .not(broker_customer: nil, carrier_id: broker_carriers.pluck(:carrier_id))
    end

    return scope if user_type == :broker || preferred_broker_carriers_kind.blank?

    # @note Apply the whitelist/blacklist
    # @note A warning is shown to brokers when a non-preferred carrier is shown
    scope = case preferred_broker_carriers_kind
            when 'whitelist'
              scope.where(id: preferred_broker_carriers.pluck(:broker_carrier_id))
            when 'blacklist'
              scope.where.not(id: preferred_broker_carriers.pluck(:broker_carrier_id))
            end

    scope
  end

  def carrier_charge_calculator(carrier_cost:, shipment:)
    BrokerCustomer::CarrierChargeCalculatorService.new(broker_customer: self, carrier_cost:, shipment:).call
  end

  def profitability_report(from_date = nil, to_date = nil)
    BrokerCustomer::ProfitabilityReportJsonService.new(broker_customer: self, from_date:, to_date:).call
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
    return unless broker.intuit_account&.connected?
    return @quickbooks_customer if @quickbooks_customer.present?

    result = nil

    if quickbooks_customer_id.present?
      result = QuickbooksAPIClient::Customers.new(broker:).find(quickbooks_customer_id)
    end
    return @quickbooks_customer = result if result.present?

    customers = QuickbooksAPIClient::Customers.new(broker:)
    result = customers.find_by_name(customer.name) # rubocop:disable Rails/DynamicFindBy
    return if result.blank?

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
    return if receivables.unpaid.none?

    receivables.unpaid.each(&:update_quickbooks_invoice)
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
