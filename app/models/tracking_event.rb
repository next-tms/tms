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
  belongs_to :event

  belongs_to :address, optional: true
  accepts_nested_attributes_for :address, allow_destroy: false, reject_if: :all_blank

  belongs_to :country
  belongs_to :region
  belongs_to :shipment
  belongs_to :terminal, optional: true
  belongs_to :user, optional: true

  serialize :time_zone

  # DateTime sanitization
  before_save :set_time_zone
  before_save :sanitize_at, if: :at_changed?

  def pretty_location
    "#{city}, #{region.abbreviation}"
  end

  private

  # DateTime sanitization
  def sanitize_datetime(datetime:, time_zone:)
    return nil if datetime.blank? || time_zone.blank?

    time_zone.local_to_utc ActiveSupport::TimeZone[time_zone.to_s].parse(datetime.to_s)
  end

  def sanitize_at
    at = sanitize_datetime(datetime: self.at, time_zone: time_zone)
    self.at = at.blank? ? DateTime.current : at
  end

  def set_time_zone
    time_zone = TrackingEvent.where(city: city, region: region).where.not(time_zone: [nil, ''])&.last&.time_zone

    unless time_zone.blank?
      self.time_zone = time_zone
      return
    end

    time_zone = Address.where(city: city, region: region).where.not(time_zone: [nil, ''])&.last&.time_zone

    unless time_zone.blank?
      self.time_zone = time_zone
      return
    end

    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])

    spots = client.spots_by_query(pretty_location)
    if spots.blank?
      self.time_zone = nil
      return
    end

    spot = spots.first
    lat = spot.json_result_object.dig('geometry', 'location', 'lat')
    lng = spot.json_result_object.dig('geometry', 'location', 'lng')
    return self.time_zone = nil if lat.blank? || lng.blank?

    self.time_zone = Timezone.lookup(lat, lng)
  end
end
