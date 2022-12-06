# frozen_string_literal: true

# == Schema Information
#
# Table name: pickups
#
# @!attribute id
#   @return []
# @!attribute confirmed_at
#   @return [Time]
# @!attribute error
#   @return [String]
# @!attribute pickup_confirmation
#   @return [String]
# @!attribute pro
#   @return [String]
# @!attribute requested_at
#   @return [Time]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute dispatcher_id
#   @return []
# @!attribute rate_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_pickups_on_dispatcher_id  (dispatcher_id)
#  index_pickups_on_rate_id        (rate_id)
#  index_pickups_on_shipment_id    (shipment_id)
#  index_pickups_on_updated_by_id  (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (dispatcher_id => users.id)
#  fk_rails_...  (rate_id => rates.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Pickup < ApplicationRecord
  after_commit :update_shipment

  belongs_to :dispatcher, class_name: 'User', required: true
  belongs_to :rate
  belongs_to :shipment
  belongs_to :updated_by, class_name: 'User', required: false

  delegate :with_calculated_freight_classes, to: :rate

  has_one :broker_carrier, through: :rate
  has_one :tracking_carrier, through: :rate

  scope :confirmed, -> { where.not(pickup_confirmation: nil) }
  scope :pending, -> { where(pickup_confirmation: nil) }

  serialize :error_object

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
      pickup_confirmation:,
      updated_by:
    )

    shipment.pro = pro if saved_change_to_pro?

    shipment.save
  end
end
