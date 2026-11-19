module Transponder
  module ORM
    class CarrierAddress < ::ORM::Base
      class << self
        def all = ::ORM::Collection.new(self, Carrier.all.flat_map(&:addresses).uniq)
        def primary_key = :id
      end

      attr_reader :city, :country_alpha2, :id, :postal_code, :region_abbreviation, :street, :street2

      def initialize( # rubocop:disable Metrics/ParameterLists
        id:,
        city: nil,
        country: nil,
        postal_code: nil,
        region_abbreviation: nil,
        street: nil,
        street2: nil
      )
        super()

        @city = city
        @country_alpha2 = country&.dig(:alpha2)
        @id = id
        @postal_code = postal_code
        @region_abbreviation = region_abbreviation
        @street = street
        @street2 = street2
      end

      def located_in?(city:, region_iso31662s:) = region_iso31662s.include?(region_iso31662) && self.city.to_s.casecmp?(city.to_s)
      def locality = [city, [region_abbreviation, postal_code].compact_blank.join(' ')].compact_blank.join(', ')
      def pretty(separator) = [street, street2, locality].compact_blank.join(separator)
      def region_iso31662 = ("#{country_alpha2}-#{region_abbreviation}" if country_alpha2.present? && region_abbreviation.present?)
      def to_address = ::Address.new(city:, country_alpha2:, region_iso31662:, street:, street2:, zip_code: postal_code)
    end
  end
end
