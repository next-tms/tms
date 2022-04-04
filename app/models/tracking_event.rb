# frozen_string_literal: true

# == Schema Information
#
# Table name: tracking_events
#
# @!attribute id
#   @return []
# @!attribute at
#   @return [Time]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute interstellar_carrier_fingerprint
#   @return [String]
# @!attribute public
#   @return [Boolean]
# @!attribute time_zone
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute address_id
#   @return []
# @!attribute country_id
#   @return []
# @!attribute event_id
#   @return []
# @!attribute region_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute terminal_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_tracking_events_on_address_id   (address_id)
#  index_tracking_events_on_country_id   (country_id)
#  index_tracking_events_on_event_id     (event_id)
#  index_tracking_events_on_region_id    (region_id)
#  index_tracking_events_on_shipment_id  (shipment_id)
#  index_tracking_events_on_terminal_id  (terminal_id)
#  index_tracking_events_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (region_id => regions.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (terminal_id => terminals.id)
#  fk_rails_...  (user_id => users.id)
#
class TrackingEvent < ApplicationRecord
  include TrackingEvent::Snitchable

  attr_writer :at_without_time_zone_string

  after_create :maybe_create_problem

  before_create :set_public

  belongs_to :event

  belongs_to :address, optional: true
  accepts_nested_attributes_for :address, allow_destroy: false, reject_if: :all_blank

  belongs_to :country
  belongs_to :region
  belongs_to :shipment
  belongs_to :terminal, optional: true
  belongs_to :user, optional: true

  # TODO: Remove
  serialize :legacy_time_zone

  validates :time_zone_name, presence: true

  def pretty_location
    "#{city}, #{region.abbreviation}"
  end

  def problem_type
    ProblemType.where(code: event.active_shipping_code)&.first
  end

  def time_zone
    return nil if time_zone_name.blank?

    ActiveSupport::TimeZone.new(time_zone_name)
  end

  private

  def maybe_create_problem
    return if problem_type.blank?

    # TODO: Use shipment.dispatcher when implemented
    assigned_to = Role
                  .find_by_name('dispatch')
                  .users
                  .broker
                  .where(broker: shipment.broker)
                  .order(Arel.sql('RANDOM()'))
                  &.last

    if assigned_to.blank?
      assigned_to = Role
                    .find_by_name('root')
                    .users
                    .broker
                    .where(broker: shipment.broker)
                    .order(Arel.sql('RANDOM()'))
                    &.last
    end

    title = "Load #{shipment.load_id} #{event.name}"
    body = "Load #{shipment.load_id} is #{event.name} per #{shipment.broker_carrier.carrier.name} API"

    Problem.create(assigned_to:, body:, problem_type:, shipment:, title:)
  end

  def set_public
    return if event.blank?

    self[:public] = event.public_by_default?
  end
end
