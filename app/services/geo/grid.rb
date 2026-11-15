module Geo
  module Grid
    extend Provider

    class << self
      def authority = Providers::AUTHORITIES.first

      def place(place_id, provider:)
        result = query(:fetch_place, id: { provider: PROVIDERS.fetch(provider), value: place_id })
        place_from(result) if result
      end

      def resolves?(provider) = PROVIDERS.key?(provider)
      def roles = %i[geocode place time_zone verification]
      def supports?(**) = true

      def time_zone(latitude:, longitude:, **)
        result = query(:fetch_time_zone, location: { latitude: latitude.to_f, longitude: longitude.to_f })
        return if result.nil?

        TimeZone.new(authority: authority_of(result[:authority]), id: result[:id])
      end

      def verify(**postal_address)
        result = query(:verify_address, address: postal_address.compact_blank.transform_keys { |key| key.to_s.camelize(:lower) })
        return if result.nil?

        location = result[:location] || {}

        Verification.new(
          address_lines: Array(result[:address_lines]),
          administrative_area: result[:administrative_area],
          authority: authority_of(result.dig(:authority, :lowest)),
          business: result[:business],
          dock: result[:dock],
          fingerprint: result[:fingerprint],
          geocode_authority: authority_of(location[:authority]),
          latitude: location[:latitude],
          locality: result[:locality],
          longitude: location[:longitude],
          place_id: nil,
          place_provider: nil,
          places: Array(result[:places]).map { place_from(it) },
          po_box: result[:po_box],
          postal_code: result[:postal_code],
          residential: result[:residential],
          verified: result[:verified]
        )
      end

      private

      def authority_of(value) = value&.downcase&.to_sym

      def cache(key, result)
        expires_at = result&.dig(:expires_at)&.then { Time.zone.parse(it) }
        Rails.cache.write(key, result, expires_at:) if expires_at&.future?
      end

      def cache_key(operation, variables) = ['geo/grid', operation, Digest::SHA256.hexdigest(variables.to_json)]

      def place_from(result)
        Place.new(
          authority: authority_of(result[:authority]),
          id: result[:id],
          name: result[:name],
          permanently_closed: result[:permanently_closed],
          types: Array(result[:freight_kit_location_types]).map(&:downcase)
        )
      end

      def query(operation, **variables)
        key = cache_key(operation, variables)
        cached = Rails.cache.read(key)
        return cached if cached

        document = "GraphQLClient::Grid::Query::#{operation.to_s.camelize}::DETAILS".constantize
        response = rescued { underscore_keys(GraphQLClient::Grid::Client.query(document, variables:).original_hash) }
        return if response.nil?

        Sentry.capture_message("Grid: #{response[:errors].pluck(:message).join(', ')}") if response[:errors].present?
        response.dig(:data, operation).tap { cache(key, it) }
      end
    end

    PROVIDERS = { 'google_maps' => 'GOOGLE' }.freeze
  end
end
