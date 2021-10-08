# frozen_string_literal: true

class TrackingEvent < ApplicationRecord
  belongs_to :event

  belongs_to :address, optional: true
  accepts_nested_attributes_for :address, allow_destroy: false, reject_if: :all_blank

  belongs_to :shipment
  belongs_to :terminal, optional: true
  belongs_to :user, optional: true

  serialize :time_zone

  # DateTime sanitization
  before_save :set_time_zone
  before_save :sanitize_at, if: :at_changed?

  def pretty_location
    "#{city}, #{state}"
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
