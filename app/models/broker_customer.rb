class BrokerCustomer < ApplicationRecord
  class << self
    def companyable_order = joins(:customer).order('customers.name')
    def ransackable_associations(_auth_object = nil) = ['customer']
  end

  include ::Instigatable
  include AccountingSyncable
  include BrokerCustomer::Instigatable
  include Companyable

  accounting_syncs :customer, match: -> { { name: customer.name } }

  after_commit :problematic_shipments_later

  audited

  before_update :update_accounting_invoices, if: :receivables_contact_id_changed?

  before_validation :set_receivables_contact_companyable, if: -> { receivables_contact&.new_record? }

  belongs_to :customer
  belongs_to :office_address, class_name: 'Address', dependent: :destroy
  belongs_to :primary_pickup_address, class_name: 'Address', dependent: :destroy
  belongs_to :receivables_contact, class_name: 'Contact', dependent: :destroy

  delegate :name, to: :customer

  enum :preferred_broker_carriers_kind, { blacklist: 'blacklist', whitelist: 'whitelist' }
  enum :receivables_schedule, { daily: 'daily', immediately: 'immediately', monthly: 'monthly', never: 'never', weekly: 'weekly' }

  has_many :broker_accessorials, dependent: :destroy
  has_many :broker_carriers, dependent: :destroy
  has_many :broker_customer_dispatchers, dependent: :destroy
  has_many :broker_customer_sales_reps, dependent: :destroy
  has_many :document_preferences, dependent: :destroy
  has_many :preferred_broker_carriers, class_name: 'PreferredBrokerCarrier', dependent: :destroy
  has_many :shipments, dependent: :nullify
  has_many :upcharge_rules, dependent: :destroy
  has_many :users, as: :companyable, dependent: :destroy

  has_many :dispatchers, through: :broker_customer_dispatchers, source: 'user'
  has_many :receivables, through: :shipments
  has_many :sales_reps, through: :broker_customer_sales_reps, source: 'user'

  monetize :default_upcharge_cents, allow_nil: true

  serialize :shipment_string_patterns, coder: YAML, type: Array
  serialize :valid_freight_classes, coder: YAML, type: Array

  validate :check_pricing_rules, if: -> { can_quote? }

  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_carriers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_customer_dispatchers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :broker_customer_sales_reps, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :customer
  accepts_nested_attributes_for :document_preferences, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :office_address, allow_destroy: true
  accepts_nested_attributes_for :preferred_broker_carriers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :primary_pickup_address, allow_destroy: true
  accepts_nested_attributes_for :receivables_contact, allow_destroy: false
  accepts_nested_attributes_for :upcharge_rules, allow_destroy: true, reject_if: :all_blank

  def eligible_broker_accessorials
    return @eligible_broker_accessorials if @eligible_broker_accessorials

    broker_customer_accessorials = broker_accessorials
    broker_accessorials = BrokerAccessorial.where(broker_customer: nil).where.not(code: [broker_customer_accessorials.map(&:code)])

    @eligible_broker_accessorials = broker_customer_accessorials.or(broker_accessorials).order(:name)
  end

  # @return [BrokerCarrier::ActiveRecord_Relation]
  def eligible_broker_carriers(user_type = :customer)
    scope = BrokerCarrier.where(broker_customer: [nil, self])

    # @note Always prefer customer-sepcific accounts
    if broker_carriers.any?
      scope = scope.where.not(id: BrokerCarrier.where(broker_customer: nil, carrier_id: broker_carriers.select(:carrier_id)))
    end

    return scope if user_type == :broker || preferred_broker_carriers_kind.blank?

    # @note Apply the whitelist/blacklist
    # @note A warning is shown to brokers when a non-preferred carrier is shown
    case preferred_broker_carriers_kind
    when 'whitelist'
      scope.where(id: preferred_broker_carriers.pluck(:broker_carrier_id))
    when 'blacklist'
      scope.where.not(id: preferred_broker_carriers.pluck(:broker_carrier_id))
    end
  end

  def carrier_charge_calculator(carrier_cost:, shipment:)
    BrokerCustomer::CarrierChargeCalculatorService.new(broker_customer: self, carrier_cost:, shipment:).call
  end

  def profitability_report(from_date = nil, to_date = nil)
    BrokerCustomer::ProfitabilityReportJsonService.new(broker_customer: self, from_date:, to_date:).call
  end

  def to_accounting_customer
    Accounting::Customer.new(
      billing_address: office_address.to_accounting_address,
      company_name: customer.legal_name,
      display_name: customer.name,
      shipping_address: primary_pickup_address&.to_accounting_address
    )
  end

  def update_accounting_invoices
    return if receivables.unpaid.none?

    receivables.unpaid.each(&:update_accounting_invoice)
  end

  private

  def check_pricing_rules
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

  def set_receivables_contact_companyable = receivables_contact.assign_attributes(companyable: self)
end
