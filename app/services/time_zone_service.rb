# frozen_string_literal: true

class TimeZoneService
  class << self
    def from_transponder_date_time(date_time)
      if date_time[:dateTimeWithZone].present?
        return Time.parse(date_time[:dateTimeWithZone]).in_time_zone(date_time[:dateTimeWithZoneName])
      end

      if date_time[:localDateTime].present?
        transponder_city = date_time.dig(:location, :city)
        transponder_country = date_time.dig(:location, :country)
        transponder_province = date_time.dig(:location, :province)

        if [transponder_city, transponder_country, transponder_province].any?(&:blank?)
          tz = default_time_zone
          return tz.parse(date_time[:localDateTime])
        end

        country = Country.find_by(alpha2_code: transponder_country[:alpha2])
        region = country.regions.where(abbreviation: transponder_province)&.first

        city = date_time.dig(:location, :city)

        unless city.blank? || region.blank?
          tz = tz_by_city_and_region(city, region)
          return tz.parse(date_time[:localDateTime])
        end
      end

      date_time[:localDate].beginning_of_day if date_time[:localDate].present?
    end

    def from_freight_kit_date_time(date_time)
      raise ArgumentError, 'date_time must be an `FreightKit::DateTime`' unless date_time.is_a?(FreightKit::DateTime)

      return date_time.date_time_with_zone if date_time.date_time_with_zone.present?

      if date_time.local_date_time.present?
        freight_kit_city = date_time.location&.city
        freight_kit_country = date_time.location&.country
        freight_kit_province = date_time.location&.province

        if [freight_kit_city, freight_kit_country, freight_kit_province].any?(&:blank?)
          tz = default_time_zone
          return tz.parse(date_time.local_date_time)
        end

        country = Country.find_by(alpha2_code: freight_kit_country.code(:alpha2).value)
        region = country.regions.where(abbreviation: date_time.location.province)&.first

        city = date_time.location.city

        unless city.blank? || region.blank?
          tz = tz_by_city_and_region(city, region)
          return tz.parse(date_time.local_date_time)
        end
      end

      date_time.local_date.beginning_of_day if date_time.local_date.present?
    end

    def default_time_zone
      Rails.logger.warn('Using TimeZoneService.default_time_zone')

      ActiveSupport::TimeZone.new(DEFAULT_TIME_ZONE_NAME)
    end

    def tz_by_city_and_region(city, region)
      last_time_zone = StandardizedAddress.where(city:, region:)&.last&.time_zone

      return last_time_zone if last_time_zone.present?

      last_time_zone = TrackingEvent.where(city:, region:)&.last&.time_zone

      return last_time_zone if last_time_zone.present?

      client = GooglePlaces::Client.new(ENV.fetch('GOOGLE_API_KEY'))

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

  DEFAULT_TIME_ZONE_NAME = 'America/Los_Angeles'

  attr_reader :output, :time_zone
end
