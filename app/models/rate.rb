# frozen_string_literal: true

# == Schema Information
#
# Table name: rates
#
# @!attribute id
#   @return []
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute error_object
#   @return [String]
# @!attribute expires_at
#   @return [Time]
# @!attribute incomplete
#   @return [Boolean]
# @!attribute interstellar_service_type
#   @return [String]
# @!attribute reference
#   @return [String]
# @!attribute request
#   @return [String]
# @!attribute response
#   @return [String]
# @!attribute shipment_fingerprint
#   @return [String]
# @!attribute transit_days
#   @return [Integer]
# @!attribute uid
#   @return [String]
# @!attribute with_calculated_freight_classes
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
#  index_rates_on_broker_carrier_id          (broker_carrier_id)
#  index_rates_on_broker_customer_id         (broker_customer_id)
#  index_rates_on_interstellar_service_type  (interstellar_service_type)
#  index_rates_on_shipment_id                (shipment_id)
#  index_rates_on_tracking_carrier_id        (tracking_carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#
class Rate < ApplicationRecord
  enum source: { api: 'api', pricing_rule: 'pricing_rule' }

  scope :with_calculated_freight_classes, -> { where(with_calculated_freight_classes: true) }
  scope :with_forced_freight_classes, -> { where(with_calculated_freight_classes: false) }
  scope :with_error, -> { where.not(error: nil).where.not(error: '') }
  scope :without_error, -> { where.not(id: with_error) }

  before_save :maybe_set_expires_at
  before_save :set_incomplete
  before_save :set_shipment_fingerprint
  before_save :set_uid

  has_one :pickup, required: false

  belongs_to :broker_carrier
  validates_presence_of :broker_carrier

  belongs_to :broker_customer, optional: true

  monetize :cost_cents

  belongs_to :shipment
  belongs_to :tracking_carrier, class_name: 'Carrier', optional: true

  has_many :rate_accessorials, dependent: :destroy
  has_many :accessorials, through: :rate_accessorials

  serialize :error_object

  # Returns the actual carrier rather than any broker associated
  def carrier
    return nil if broker_carrier.blank?

    if broker_carrier.carrier.acts_as_broker?
      tracking_carrier
    else
      broker_carrier
    end
  end

  def pretty_service_type
    return '' if interstellar_service_type.blank?

    "#{interstellar_service_type.sub('_', ' ').titleize.sub('Am', 'AM').sub('Pm', 'PM')} LTL"
  end

  def to_param
    uid.to_s
  end

  private

  def maybe_set_expires_at
    self.expires_at = DateTime.current + 14.days if expires_at.blank?
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
