# frozen_string_literal: true

class Pickup < ApplicationRecord
  after_commit :update_shipment

  belongs_to :rate
  belongs_to :shipment
  belongs_to :updated_by, class_name: 'User', required: false

  delegate :with_calculated_freight_classes, to: :rate

  has_one :broker_carrier, through: :rate
  has_one :tracking_carrier, through: :rate

  scope :confirmed, -> { where.not(pickup_confirmation: nil) }
  scope :pending, -> { where(pickup_confirmation: nil) }

  validate :shipment_complete

  def confirmed?
    !pickup_confirmation.blank?
  end

  def pending?
    !confirmed?
  end

  def rate_uid=(rate_uid)
    self.rate = Rate.find_by_uid(rate_uid)
    self.shipment = rate.shipment
  end

  private

  def shipment_complete
    errors.add(:shipment, 'must not be incomplete') if shipment.incomplete?
  end

  def update_shipment
    return if shipment.blank? || !shipment.picked_up_at.blank?

    shipment = self.shipment

    shipment.assign_attributes(
      applied_rate: rate,
      dispatched_at: DateTime.current,
      updated_by: updated_by
    )

    shipment.pickup_confirmation = pickup_confirmation
    shipment.pro = pro if saved_change_to_pro?

    shipment.save
  end
end
