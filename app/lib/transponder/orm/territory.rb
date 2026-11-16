module Transponder
  module ORM
    class Territory
      attr_reader :country_alpha2, :postal_codes, :region_abbreviation

      def initialize(country:, postal_codes: [], region_abbreviation: nil)
        @country_alpha2 = country[:alpha2]
        @postal_codes = postal_codes
        @region_abbreviation = region_abbreviation
      end

      def name = [region_abbreviation, country_alpha2].compact_blank.join(', ')
      def to_s = postal_codes.any? ? "#{name} (#{postal_codes.join(', ')})" : name
    end
  end
end
