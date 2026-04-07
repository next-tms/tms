# frozen_string_literal: true

# == Schema Information
#
# Table name: rates
#
# @!attribute id
#   @return []
# @!attribute api_request
#   @return [String]
# @!attribute api_response
#   @return [String]
# @!attribute breakdown
#   @return [Hash]
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute expires_at
#   @return [Time]
# @!attribute freight_kit_service_type
#   @return [String]
# @!attribute incomplete
#   @return [Boolean]
# @!attribute reference
#   @return [String]
# @!attribute shipment_fingerprint
#   @return [String]
# @!attribute source
#   @return [String]
# @!attribute transit_days
#   @return [Integer]
# @!attribute uid
#   @return [String]
# @!attribute declared_freight_classes
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_customer_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
#
# Indexes
#
#  index_rates_on_broker_carrier_id         (broker_carrier_id)
#  index_rates_on_broker_customer_id        (broker_customer_id)
#  index_rates_on_freight_kit_service_type  (freight_kit_service_type)
#  index_rates_on_shipment_id               (shipment_id)
#  index_rates_on_tracking_carrier_id       (tracking_carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#
class Rate < ApplicationRecord
  include HasAPI

  enum :source, { api: 'api', pricing_rule: 'pricing_rule' }

  before_save :set_expires_at, if: -> { new_record? }
  before_save :set_incomplete, if: -> { new_record? }
  before_save :set_shipment_fingerprint, if: -> { new_record? }
  before_save :set_uid, if: -> { new_record? }

  belongs_to :broker_carrier
  belongs_to :broker_customer, optional: true
  belongs_to :shipment
  belongs_to :tracking_carrier, class_name: 'Carrier', optional: true

  has_many :pickups, dependent: :restrict_with_exception
  has_many :rate_accessorials, dependent: :destroy

  has_many :accessorials, through: :rate_accessorials

  monetize :cost_cents

  scope :calculated_freight_classes, -> { where(declared_freight_classes: false) }
  scope :declared_freight_classes, -> { where(declared_freight_classes: true) }

  def applied?
    shipment.applied_rate == self
  end

  # Returns the actual carrier rather than any broker associated
  def carrier
    return if broker_carrier.blank?

    return tracking_carrier if broker_carrier.carrier.acts_as_broker?

    broker_carrier
  end

  def preferred?
    return true if broker_customer.blank?

    shipment.broker_customer.eligible_broker_carriers(user_type: :customer).include?(broker_carrier)
  end

  def pretty_service_type
    return '' if freight_kit_service_type.blank?

    "#{freight_kit_service_type.sub("_", " ").titleize.sub("Am", "AM").sub("Pm", "PM")} LTL"
  end

  def to_param
    uid.to_s
  end

  private

  def set_expires_at
    self.expires_at ||= Time.current + 14.days
  end

  def set_incomplete
    self.incomplete = shipment.incomplete?
  end

  def set_shipment_fingerprint
    self.shipment_fingerprint = shipment.fingerprint
  end

  def set_uid
    self.uid = SecureRandom.uuid
  end
end
