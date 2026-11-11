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

  def charge = @charge ||= shipment.broker_customer&.carrier_charge_calculator(carrier_cost: cost, shipment:)

  def preferred? = broker_customer.blank? || shipment.broker_customer.eligible_broker_carriers(:customer).include?(broker_carrier)

  def pretty_service_type
    return '' if freight_kit_service_type.blank?

    "#{freight_kit_service_type.sub('_', ' ').titleize.sub('Am', 'AM').sub('Pm', 'PM')} LTL"
  end

  def to_param
    uid.to_s
  end

  private

  def set_expires_at
    self.expires_at ||= 14.days.from_now
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
