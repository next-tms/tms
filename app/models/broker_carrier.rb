# == Schema Information
#
# Table name: broker_carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute account
#   @return [String]
# @!attribute account_desc
#   @return [String]
# @!attribute accounting_notes
#   @return [String]
# @!attribute create_invoice_on_pickup
#   @return [Boolean]
# @!attribute days_to_pay_after_invoice_date
#   @return [Integer]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute ignore_bol_requires_tracking_number
#   @return [Boolean]
# @!attribute password
#   @return [String]
# @!attribute quote_padding_cents
#   @return [Integer]
# @!attribute quote_padding_currency
#   @return [String]
# @!attribute shipments_count
#   @return [Integer]
# @!attribute username
#   @return [String]
# @!attribute website_password
#   @return [String]
# @!attribute website_username
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_vendor_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute carrier_id
#   @return [Integer]
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_broker_carriers_on_broker_customer_id        (broker_customer_id)
#  index_broker_carriers_on_carrier_id                (carrier_id)
#  index_broker_carriers_on_check_mailing_address_id  (check_mailing_address_id)
#  index_broker_carriers_on_shipments_count           (shipments_count)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
class BrokerCarrier < ApplicationRecord
  class << self
    def companyable_order
      joins(:carrier).order('carriers.name')
    end

    def ransackable_attributes(auth_object = nil)
      [ 'name', 'shipments_count' ]
    end

    def ransackable_associations(auth_object = nil)
      [ 'broker_customer', 'carrier' ]
    end
  end

  include AccountingSyncable
  include Companyable

  accounting_syncs :vendor, match: -> { { name: carrier.name } }

  audited

  # API key belonging to customer
  encrypts :encrypted_api_key

  belongs_to :carrier
  belongs_to :broker_customer, optional: true

  belongs_to :check_mailing_address, class_name: 'Address', optional: true

  delegate :acts_as_broker?, to: :carrier
  delegate :scac, to: :carrier

  has_many :overlength_rules
  has_many :payments
  has_many :payment_transactions
  has_many :preferred_by_broker_customers, class_name: 'PreferredBrokerCarrier'
  has_many :pricing_rules
  has_many :rates
  has_many :shipments
  has_many :terminals, through: :carrier

  has_many :pickups, through: :rates

  accepts_nested_attributes_for :check_mailing_address
  accepts_nested_attributes_for :overlength_rules, allow_destroy: true
  accepts_nested_attributes_for :pricing_rules, allow_destroy: true

  monetize :quote_padding_cents

  scope :api_configured, -> do
    ids = joins(:carrier)
          .where(carrier: Carrier.freight_kit_api)
          .select(&:api_configured?)
          .map(&:id)

    where(id: ids)
  end
  scope :api_unconfigured, -> { where.not(id: api_configured.ids) }
  scope :blanket, -> { where(broker_customer: nil) }

  def api_configured?
    return false if carrier.broker_carrier_credential_columns.none?

    carrier.broker_carrier_credential_columns.map { |column| public_send(column) }.all?(&:present?)
  end

  def bol_requires_tracking_number?
    !ignore_bol_requires_tracking_number && carrier.bol_requires_tracking_number?
  end

  def broker_customer_specific_name
    return carrier.name if broker_customer.blank?

    "#{carrier.name} - #{broker_customer.customer.name}"
  end
  alias_method :name, :broker_customer_specific_name

  def to_accounting_vendor
    Accounting::Vendor.new(
      billing_address: check_mailing_address&.to_accounting_address,
      company_name: carrier.name,
      display_name: carrier.name,
    )
  end

  def to_freight_kit_carrier
    @to_freight_kit_carrier ||= FreightKitAPIClient::Services::BuildAPIClient.call(broker_carrier: self)
  end

  def to_freight_kit_tariff
    return if overlength_rules.blank?

    freight_kit_overlength_rules = overlength_rules.map do |overlength_rule|
      fee_cents = overlength_rule.cost_cents
      max_length = Measured::Length.new(overlength_rule.max_length, :inches) if overlength_rule.max_length.present?
      min_length = Measured::Length.new(overlength_rule.min_length, :inches)

      { fee_cents:, max_length:, min_length: }
    end

    FreightKit::Tariff.new(overlength_rules: freight_kit_overlength_rules)
  end

  delegate :pickup_number_is_tracking_number?, to: :carrier
end
