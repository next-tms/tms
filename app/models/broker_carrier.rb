# frozen_string_literal: true

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
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute carrier_id
#   @return [Integer]
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_broker_carriers_on_broker_customer_id        (broker_customer_id)
#  index_broker_carriers_on_broker_id                 (broker_id)
#  index_broker_carriers_on_carrier_id                (carrier_id)
#  index_broker_carriers_on_check_mailing_address_id  (check_mailing_address_id)
#  index_broker_carriers_on_shipments_count           (shipments_count)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
class BrokerCarrier < ApplicationRecord
  scope :api_configured, -> { where.not(password: [nil, '']) }
  scope :api_unconfigured, -> { where.not(id: api_configured) }
  scope :blanket, -> { where(broker_customer: nil) }

  belongs_to :carrier
  belongs_to :broker
  belongs_to :broker_customer, required: false, optional: true

  belongs_to :check_mailing_address, class_name: 'Address', required: false

  delegate :scac, to: :carrier

  has_many :contacts
  has_many :overlength_rules
  has_many :payment_transactions
  has_many :preferred_by_broker_customers, class_name: 'PreferredBrokerCarrier', foreign_key: :broker_carrier_id
  has_many :pricing_rules
  has_many :rates
  has_many :shipments
  has_many :terminals, through: :carrier

  has_many :pickups, through: :rates

  accepts_nested_attributes_for :check_mailing_address
  accepts_nested_attributes_for :contacts
  accepts_nested_attributes_for :overlength_rules
  accepts_nested_attributes_for :pricing_rules

  monetize :quote_padding_cents

  def api_configured?
    !((account.blank? && username.blank?) || password.blank?)
  end

  def bol_requires_tracking_number?
    !ignore_bol_requires_tracking_number && as_interstellar_carrier&.bol_requires_tracking_number?
  end

  def broker_customer_specific_name
    if broker_customer.blank?
      carrier.name
    else
      "#{carrier.name} - #{broker_customer.customer.name}"
    end
  end
  alias name broker_customer_specific_name

  def as_interstellar_carrier
    @as_interstellar_carrier ||= InterstellarApiClient::Services::BuildApiClient.call(broker_carrier: self)
  end

  def to_interstellar_tariff
    return nil if overlength_rules.blank?

    interstellar_overlength_rules = []

    overlength_rules.each do |overlength_rule|
      interstellar_overlength_rules << {
        fee_cents: overlength_rule.cost_cents,
        max_length: overlength_rule.max_length.blank? ? nil : Measured::Length.new(overlength_rule.max_length, :inches),
        min_length: Measured::Length.new(overlength_rule.min_length, :inches)
      }
    end

    Interstellar::Tariff.new(
      overlength_rules: interstellar_overlength_rules
    )
  end

  def pickup_number_is_tracking_number?
    return false if as_interstellar_carrier.blank?

    as_interstellar_carrier.pickup_number_is_tracking_number?
  end
end
