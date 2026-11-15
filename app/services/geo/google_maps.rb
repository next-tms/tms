module Geo
  module GoogleMaps
    extend Provider

    class << self
      def authority = :commercial

      def place(place_id, **)
        response = commit { CompressedHTTPClient.get(url(:places, "/v1/places/#{ERB::Util.url_encode(place_id)}"), **options(:places, FIELD_MASK)) }
        return if response.nil?

        Place.new(
          authority:,
          id: place_id,
          name: response.dig(:display_name, :text),
          permanently_closed: response[:business_status]&.then { it == 'CLOSED_PERMANENTLY' },
          types: location_types(response[:types])
        )
      end

      def resolves?(provider) = provider == key
      def roles = %i[geocode place time_zone verification]
      def supports?(**) = true

      def time_zone(latitude:, longitude:, timestamp: Time.current)
        query = { key: api_key(:time_zone), location: "#{latitude},#{longitude}", timestamp: timestamp.to_i }.to_query
        response = commit { CompressedHTTPClient.get(url(:time_zone, "/maps/api/timezone/json?#{query}"), **options(:time_zone)) }
        return if response.nil?
        return TimeZone.new(authority:, id: response[:time_zone_id]) if response[:status] == 'OK'

        return if response[:status] == 'ZERO_RESULTS'

        Sentry.capture_message("Time Zone API: #{response[:status]} #{response[:error_message]}".strip)
        nil
      end

      def verify(**postal_address)
        json = { address: postal_address.compact_blank.transform_keys { |key| key.to_s.camelize(:lower) } }
        endpoint = url(:address_validation, '/v1:validateAddress')
        response = commit { CompressedHTTPClient.post(endpoint, json:, **options(:address_validation)) }
        return if response.nil?

        verification(response[:result] || {})
      end

      private

      def api_key(api) = endpoint(api).user
      def endpoint(api) = URI.parse(ENV.fetch("GOOGLE_#{api.upcase}_URL"))
      def location_types(types) = Array(types).filter_map { LOCATION_TYPES[it] }.uniq
      def options(api, headers = {}) = { headers: headers.merge('X-Goog-Api-Key' => api_key(api)), timeout: Provider::TIMEOUT }
      def url(api, path) = "#{endpoint(api).tap { |uri| uri.user = nil }.to_s.chomp('/')}#{path}"

      def verification(result)
        location = result.dig(:geocode, :location) || {}
        metadata = result[:metadata] || {}
        postal_address = result.dig(:address, :postal_address) || {}

        Verification.new(
          address_lines: Array(postal_address[:address_lines]),
          administrative_area: postal_address[:administrative_area],
          authority:,
          business: metadata[:business],
          dock: nil,
          fingerprint: nil,
          geocode_authority: authority,
          latitude: location[:latitude],
          locality: postal_address[:locality],
          longitude: location[:longitude],
          place_id: result.dig(:geocode, :place_id).presence,
          place_provider: key,
          places: nil,
          po_box: metadata[:po_box],
          postal_code: postal_address[:postal_code],
          residential: metadata[:residential],
          verified: verified?(result[:verdict] || {})
        )
      end

      def verified?(verdict)
        verdict[:address_complete] == true && !verdict[:has_unconfirmed_components] &&
          UNVERIFIED_GRANULARITIES.exclude?(verdict[:validation_granularity])
      end
    end

    FIELD_MASK = { 'X-Goog-FieldMask' => 'businessStatus,displayName,types' }.freeze
    LOCATION_TYPES = YAML
                     .load_file(Rails.root.join('config/freight_kit_location_types.yml'))
                     .flat_map { |type, google_types| google_types.map { [it, type] } }
                     .to_h
                     .freeze
    UNVERIFIED_GRANULARITIES = [nil, 'OTHER'].freeze
  end
end
