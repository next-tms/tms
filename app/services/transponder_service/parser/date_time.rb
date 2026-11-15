module TransponderService
  module Parser
    class DateTime
      class << self
        # @return [Boolean|NilClass]
        def call(date_time)
          return if date_time.blank?

          if date_time[:iso8601].present? && date_time[:time_zone].present?
            return Time.zone.parse(date_time[:iso8601]).in_time_zone(date_time[:time_zone])
          end

          city = date_time.dig(:location, :city)
          return if city.blank?

          date_or_date_time = date_time[:local_date_time].presence || date_time[:local_date]
          return if date_or_date_time.blank?

          transponder_region_abbreviation = date_time.dig(:location, :region_abbreviation)
          return if transponder_region_abbreviation.blank?

          country = Parser::Country.call(date_time.dig(:location, :country))
          return if country.blank?

          region = country.regions.find_by(abbreviation: transponder_region_abbreviation)
          return if region.blank?

          tz = tz_by_city_and_region(city, region)
          return if tz.blank?

          tz.parse(date_or_date_time)
        end

        private

        def tz_by_city_and_region(city, region)
          record = [Address, TrackingEvent]
                   .map do |model|
            model.where(city:, region_iso31662: region.iso31662).where.not(time_zone_name: nil).where.not(time_zone_name: '').last
          end
                   .flatten
                   .compact_blank
                   .first

          return record.time_zone if record.present?

          verification = Geo.verify(administrative_area: region.abbreviation, locality: city, region_code: region.country.alpha2)
          return if verification&.latitude.blank? || verification.longitude.blank?

          time_zone_name = Geo.time_zone(latitude: verification.latitude, longitude: verification.longitude)
          return if time_zone_name.blank?

          ActiveSupport::TimeZone.new(time_zone_name)
        end
      end
    end
  end
end
