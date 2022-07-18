# frozen_string_literal: true

class TimeZoneService
  DEFAULT_TIME_ZONE_NAME = 'America/Los_Angeles'

  attr_reader :output, :time_zone

  def self.from_interstellar_date_time(date_time)
    raise ArgumentError, 'date_time must be an `Interstellar::DateTime`' unless date_time.is_a?(Interstellar::DateTime)

    return date_time.date_time_with_zone unless date_time.date_time_with_zone.blank?

    unless date_time.local_date_time.blank?
      interstellar_city = date_time.location&.city
      interstellar_country = date_time.location&.country
      interstellar_province = date_time.location&.province

      if [interstellar_city, interstellar_country, interstellar_province].any?(&:blank?)
        tz = default_time_zone
        return tz.parse(date_time.local_date_time)
      end

      country = Country.find_by_alpha2_code(interstellar_country.code(:alpha2).value)
      region = country.regions.where(abbreviation: date_time.location.province)&.first

      city = date_time.location.city

      unless city.blank? || region.blank?
        tz = tz_by_city_and_region(city, region)
        return tz.parse(date_time.local_date_time)
      end
    end

    date_time.local_date.beginning_of_day unless date_time.local_date.blank?
  end

  def self.default_time_zone
    Rails.logger.warn 'Using TimeZoneService.default_time_zone'

    ActiveSupport::TimeZone.new(DEFAULT_TIME_ZONE_NAME)
  end

  def self.tz_by_city_and_region(city, region)
    last_time_zone = StandardizedAddress.where(city:, region:)&.last&.time_zone

    return last_time_zone unless last_time_zone.blank?

    last_time_zone = TrackingEvent.where(city:, region:)&.last&.time_zone

    return last_time_zone unless last_time_zone.blank?

    client = GooglePlaces::Client.new(Rails.application.credentials.google.api_key)

    spots = client.spots_by_query("#{city}, #{region.abbreviation}, #{region.country.alpha2_code}")

    return default_time_zone if spots.blank?

    spot = spots.first
    lat = spot.json_result_object.dig('geometry', 'location', 'lat')
    lng = spot.json_result_object.dig('geometry', 'location', 'lng')

    return default_time_zone if lat.blank? || lng.blank?

    tz = Timezone.lookup(lat, lng)

    ActiveSupport::TimeZone.new(tz.name)
  end
end
