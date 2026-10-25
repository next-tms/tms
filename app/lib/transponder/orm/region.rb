module Transponder
  module ORM
    class Region < Base
      class << self
        # Rebuilt whenever Country.all is a different collection, so regions never lag behind countries
        def all
          countries = Country.all
          return @all if @all && @countries.equal?(countries)

          @countries = countries
          @all = Collection.new(self, countries.flat_map { |country| country.regions.to_a })
        end

        def primary_key = :iso31662
      end

      attr_reader :iso31662

      # Only iso31662 is required, so records that store a code Transponder no longer returns stay readable
      def initialize(iso31662:, abbreviation: nil, country: nil, name: nil)
        @abbreviation = abbreviation
        @country = country
        @iso31662 = iso31662
        @name = name
      end

      def abbreviation = @abbreviation ||= iso31662.split('-', 2).last
      def country = @country ||= Country.find_or_initialize_by(alpha2: iso31662.split('-', 2).first)
      def name = @name || iso31662
    end
  end
end
