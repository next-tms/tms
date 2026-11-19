module Grid
  module ORM
    class Country < ::ORM::Base
      class << self
        def all
          reset if @memo_expires_at&.past?

          @all ||= ::ORM::Collection.new(self, fetch.map { |attributes| new(**attributes) }).tap { @memo_expires_at = MEMO_EXPIRES_IN.from_now }
        end

        def primary_key = :alpha2

        def reset
          Region.reset
          super
        end

        def find_by(**conditions)
          return super unless conditions.key?(:name)

          super(**conditions.except(:name), alpha2: conditions[:name].to_s.strip.presence&.then { |name| resolved_alpha2(name) })
        end

        private

        def fetch
          Rails.cache.fetch("grid@#{ORM.version}/countries", expires_in: CACHE_EXPIRES_IN) do
            response = GraphQLClient::Grid::Client.query(GraphQLClient::Grid::Query::FetchCountries::DETAILS)
            errors = response.original_hash['errors']
            raise GraphQL::Client::Error, errors.pluck('message').join(', ') if errors.present?

            response
              .original_hash
              .dig('data', 'fetchCountries')
              .map { |country| country.deep_transform_keys { |key| key.underscore.to_sym } }
          end
        end

        def query_alpha2(name)
          response = GraphQLClient::Grid::Client.query(GraphQLClient::Grid::Query::FetchCountries::NAMED, variables: { name: })
          errors = response.original_hash['errors']
          raise GraphQL::Client::Error, errors.pluck('message').join(', ') if errors.present?

          response.original_hash.dig('data', 'fetchCountries', 0, 'alpha2')
        end

        def named_cache_key(name) = "grid@#{ORM.version}/countries/named/#{name.downcase}"
        def resolved_alpha2(name) = Rails.cache.fetch(named_cache_key(name), expires_in: CACHE_EXPIRES_IN) { query_alpha2(name) }
      end

      CACHE_EXPIRES_IN = 1.day
      MEMO_EXPIRES_IN = 1.hour

      attr_reader :alpha2, :alpha3, :numeric, :postal_code, :postal_code_format, :postal_code_label, :regions

      # Only alpha2 is required, so records that store a code Grid no longer returns stay readable
      def initialize( # rubocop:disable Metrics/ParameterLists
        alpha2:,
        alpha3: nil,
        name: nil,
        numeric: nil,
        postal_code: true,
        postal_code_format: nil,
        postal_code_label: nil,
        regions: []
      )
        super()

        @alpha2 = alpha2
        @alpha3 = alpha3
        @name = name
        @numeric = numeric
        @postal_code = postal_code
        @postal_code_format = postal_code_format
        @postal_code_label = postal_code_label
        @regions = ::ORM::Collection.new(Region, regions.map { |attributes| Region.new(country: self, **attributes) })
      end

      def cache_version = [name, postal_code, postal_code_format, postal_code_label].join('/')

      def format_address(str)
        return if str.blank?

        case alpha2
        when 'US' then StreetAddress::US.parse_address(str).to_s
        end

        str
      end

      def name = @name || alpha2

      def valid_postal_code?(postal_code) = postal_code_format.nil? || postal_code.upcase.match?(/\A(?:#{postal_code_format})\z/)

      def valid_street?(street)
        case alpha2
        when 'US' then return !street.start_with?(/\d*-\d*/)
        end

        true
      end
    end
  end
end
