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
  attr_writer :at_without_time_zone_string

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

  # DateTime sanitization
  before_validation :set_time_zone_name
  before_validation :set_at_from_at_without_time_zone_string

  def pretty_location
    "#{city}, #{region.abbreviation}"
  end

  def time_zone
    return nil if time_zone_name.blank?

    ActiveSupport::TimeZone.new(time_zone_name)
  end

  private

  def sanitize_datetime(datetime:, time_zone:)
    return nil unless datetime.is_a?(String)
    return nil if datetime.blank? || time_zone.blank?

    time_zone.parse(datetime)
  end

  def set_at_from_at_without_time_zone_string
    return if @at_without_time_zone_string.blank?

    new_at = sanitize_datetime(datetime: @at_without_time_zone_string, time_zone:)
    self.at = new_at.blank? ? DateTime.current : new_at
  end

  def set_time_zone_name
    last_time_zone_name = StandardizedAddress.where(region:)&.last&.time_zone_name

    unless last_time_zone_name.blank?
      self.time_zone_name = last_time_zone_name
      return
    end

    last_time_zone_name = TrackingEvent.where(region:)&.last&.time_zone_name

    unless last_time_zone_name.blank?
      self.time_zone_name = last_time_zone_name
      return
    end

    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])

    spots = client.spots_by_query(pretty_location)
    if spots.blank?
      self.time_zone_name = nil
      return
    end

    spot = spots.first
    lat = spot.json_result_object.dig('geometry', 'location', 'lat')
    lng = spot.json_result_object.dig('geometry', 'location', 'lng')
    return self.time_zone_name = nil if lat.blank? || lng.blank?

    self.time_zone_name = Timezone.lookup(lat, lng)
  end
end
