# == Schema Information
#
# Table name: pickup_requests
#
# @!attribute id
#   @return []
# @!attribute accepted_pickup_at
#   @return [Time]
# @!attribute accepted_pickup_on
#   @return [Date]
# @!attribute canceled_at
#   @return [Time]
# @!attribute reschedule_reason
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute created_by_id
#   @return []
#
# Indexes
#
#  index_pickup_requests_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
# @!attribute id
#   @return []
# @!attribute accepted_pickup_at
#   @return [Time]
# @!attribute accepted_pickup_on
#   @return [Date]
# @!attribute canceled_at
#   @return [Time]
# @!attribute reschedule_reason
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute created_by_id
#   @return []
#
# Indexes
#
#  index_pickup_requests_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
class PickupRequest < ApplicationRecord
  class << self
    def audits = Audit.where(auditable: all)
    def ransackable_associations(_auth_object = nil) = []
    def ransackable_attributes(_auth_object = nil) = ['accepted_pickup_at', 'accepted_pickup_on', 'canceled_at', 'created_at', 'id']
  end

  REASONS = ['capacity', 'closed', 'missed', 'shipper', 'special_equipment', 'too_busy', 'weather'].freeze

  audited

  before_save -> { self.accepted_pickup_at = Time.current }, if: :accepted_pickup_on_changed?

  belongs_to :created_by, class_name: 'User', optional: true

  enum :reschedule_reason, REASONS.index_by(&:itself), prefix: true, validate: { allow_nil: true }

  has_many :shipments, dependent: :restrict_with_exception, inverse_of: :pickup_request

  scope :active, -> { where(canceled_at: nil) }
  scope :missed, -> { active.where(id: Shipment.missed_pickup.select(:pickup_request_id)) }

  def cancel = update(canceled_at: Time.current)
  def canceled? = canceled_at.present?

  def miss!
    transaction do
      update!(reschedule_reason: :missed)
      shipments.select(&:missed_pickup?).each { |shipment| shipment.update!(pickup_driver_assigned_at: nil, pickup_on: next_pickup_on) }
    end
  end

  def reschedule_reason_applicable? = rescheduled? || reschedule_reason.present?
  def rescheduled? = shipments.any? { |shipment| shipment.pickup_on != accepted_pickup_on }

  def status
    return 'Cancelled' if canceled?
    return 'Departed' if shipments.all?(&:picked_up?)
    return 'En Route' if shipments.any? { |shipment| shipment.pickup_driver_assigned_at.present? }
    return 'Rescheduled' if rescheduled?

    'Accepted'
  end

  private

  def next_pickup_on = Setting.time_zone.today.then { |today| today.on_weekday? ? today : today.next_weekday }
end
