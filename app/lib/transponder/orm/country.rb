module Transponder
  module ORM
    class Country < Base
      CACHE_EXPIRES_IN = 1.day
      # Each process rebuilds its collections from Rails.cache this often, so long-running workers see new Transponder data
      MEMO_EXPIRES_IN = 1.hour

      class << self
        def all
          reset if @memo_expires_at&.past?

          @all ||= Collection.new(self, fetch.map { |attributes| new(**attributes) }).tap { @memo_expires_at = MEMO_EXPIRES_IN.from_now }
        end

        def primary_key = :alpha2

        def reset
          Region.reset
          super
        end

        private

        def fetch
          Rails.cache.fetch("transponder@#{ORM.version}/countries", expires_in: CACHE_EXPIRES_IN) do
            response = GraphQLClient::Transponder::Client.query(GraphQLClient::Transponder::Query::FetchCountries::DETAILS)
            errors = response.original_hash['errors']
            raise GraphQL::Client::Error, errors.pluck('message').join(', ') if errors.present?

            response.original_hash.dig('data', 'fetchCountries').map do |country|
              country.deep_transform_keys { |key| key.underscore.to_sym }
            end
          end
        end
      end

      attr_reader :alpha2, :alpha3, :numeric, :regions

      # Only alpha2 is required, so records that store a code Transponder no longer returns stay readable
      def initialize(alpha2:, alpha3: nil, name: nil, numeric: nil, regions: [])
        super()

        @alpha2 = alpha2
        @alpha3 = alpha3
        @name = name
        @numeric = numeric
        @regions = Collection.new(Region, regions.map { |attributes| Region.new(country: self, **attributes) })
      end

      def format_address(str)
        return if str.blank?

        case alpha2
        when 'US' then StreetAddress::US.parse_address(str).to_s
        end

        str
      end

      def name = @name || alpha2

      def valid_postal_code?(postal_code)
        case alpha2
        when 'CA' then return postal_code.match?(/^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$/)
        when 'US' then return postal_code.match?(/^\d{5}(?:-\d{4})?$/)
        end

        true
      end

      def valid_street?(street)
        case alpha2
        when 'US' then return !street.start_with?(/\d*-\d*/)
        end

        true
      end
    end
  end
end
