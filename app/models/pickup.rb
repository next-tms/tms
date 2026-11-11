class Pickup < ApplicationRecord
  include HasAPI

  after_commit :update_shipment

  before_validation :set_shipment, if: -> { will_save_change_to_rate_id? }

  belongs_to :dispatcher, class_name: 'User'
  belongs_to :rate
  belongs_to :shipment
  belongs_to :updated_by, class_name: 'User', optional: true

  delegate :declared_freight_classes, to: :rate

  has_one :broker_carrier, through: :rate
  has_one :tracking_carrier, through: :rate

  scope :confirmed, -> { where.not(pickup_confirmation: nil) }
  scope :pending, -> { where(pickup_confirmation: nil) }

  validate :validate_shipment_complete

  def confirmed?
    pickup_confirmation.present?
  end

  def pending?
    !confirmed?
  end

  def rate_uid=(rate_uid)
    self.rate = Rate.find_by(uid: rate_uid)
  end

  private

  def set_shipment
    self.shipment = rate&.shipment
  end

  def update_shipment
    return if shipment.blank? || shipment.picked_up_at.present?

    shipment.assign_attributes(applied_rate: rate, dispatched_at: Time.current, pickup_confirmation:, updated_by:)

    shipment.pro = pro if saved_change_to_pro?

    shipment.save
  end

  def validate_shipment_complete
    return unless shipment.incomplete?

    errors.add(:shipment, 'must not be complete')
  end
end
