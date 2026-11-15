module Geo
  module Smarty
    extend Provider

    class << self
      def authority = :certified
      def roles = %i[geocode verification]

      def supports?(**query) = REGION_CODES.include?(query[:region_code]) && (street?(query) || query[:postal_code].present?)
      def verify(**postal_address) = street?(postal_address) ? street(postal_address) : zip_code(postal_address)

      private

      def lookup(api, path, params)
        endpoint = URI.parse(ENV.fetch("SMARTY_#{api.upcase}_URL"))
        credentials = { 'auth-id' => endpoint.user, 'auth-token' => endpoint.password }
        url = "#{endpoint.tap { |uri| uri.user = nil }.to_s.chomp('/')}#{path}?#{params.compact_blank.merge(credentials).to_query}"

        commit { CompressedHTTPClient.get(url, timeout: Provider::TIMEOUT) }&.first
      end

      def postal_code(components) = [components[:zipcode], components[:plus4_code]].compact_blank.join('-').presence
      def rdi?(metadata, value) = metadata[:rdi].presence&.eql?(value)
      def state(administrative_area, region_code) = administrative_area.presence || region_code.presence_in(REGION_CODES.excluding('US'))

      def street(postal_address)
        address_lines = postal_address[:address_lines]
        params = {
          'candidates' => 1,
          'city' => postal_address[:locality],
          'state' => state(postal_address[:administrative_area], postal_address[:region_code]),
          'street' => address_lines.first,
          'street2' => address_lines.drop(1).join(' '),
          'zipcode' => postal_address[:postal_code]
        }
        candidate = lookup(:us_street, '/street-address', params)
        return if candidate.blank?

        components = candidate.fetch(:components, {})
        metadata = candidate.fetch(:metadata, {})

        Verification.new(
          address_lines: [candidate[:delivery_line_1], candidate[:delivery_line_2]].compact_blank,
          administrative_area: components[:state_abbreviation],
          authority:,
          business: rdi?(metadata, 'Commercial'),
          dock: nil,
          fingerprint: nil,
          geocode_authority: authority,
          latitude: metadata[:latitude],
          locality: components[:city_name],
          longitude: metadata[:longitude],
          place_id: nil,
          place_provider: nil,
          places: nil,
          po_box: metadata[:record_type] == 'P',
          postal_code: postal_code(components),
          residential: rdi?(metadata, 'Residential'),
          verified: candidate.dig(:analysis, :dpv_match_code) == 'Y'
        )
      end

      def street?(query) = Array(query[:address_lines]).compact_blank.any?

      def zip_code(postal_address)
        result = lookup(:us_zipcode, '/lookup', 'zipcode' => postal_address[:postal_code])
        zip_code = result&.dig(:zipcodes, 0)
        return if zip_code.blank?

        Verification.new(
          address_lines: [],
          administrative_area: zip_code[:state_abbreviation],
          authority:,
          business: nil,
          dock: nil,
          fingerprint: nil,
          geocode_authority: authority,
          latitude: zip_code[:latitude],
          locality: zip_code[:default_city] || result.dig(:city_states, 0, :city),
          longitude: zip_code[:longitude],
          place_id: nil,
          place_provider: nil,
          places: nil,
          po_box: nil,
          postal_code: zip_code[:zipcode],
          residential: nil,
          verified: false
        )
      end
    end

    REGION_CODES = ['AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'US', 'VI'].freeze
  end
end
