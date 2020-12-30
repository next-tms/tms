# frozen_string_literal: true

class Rate < ApplicationRecord
  scope :with_calculated_freight_classes, -> { where(with_calculated_freight_classes: true) }
  scope :with_forced_freight_classes, -> { where(with_calculated_freight_classes: false) }
  scope :without_error, -> { where(error: nil) }

  before_save :maybe_set_expires_at
  before_save :set_incomplete
  before_save :set_shipment_fingerprint
  before_save :set_uid

  belongs_to :broker_carrier
  validates_presence_of :broker_carrier

  belongs_to :broker_customer, optional: true

  monetize :cost_cents

  belongs_to :shipment
  belongs_to :tracking_carrier, class_name: 'Carrier', optional: true

  has_many :rate_accessorials, dependent: :delete_all
  has_many :accessorials, through: :rate_accessorials

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
    return '' if reactive_shipping_service_type.blank?
    "#{reactive_shipping_service_type.sub('_', ' ').titleize.sub('Am', 'AM').sub('Pm', 'PM')} LTL"
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
