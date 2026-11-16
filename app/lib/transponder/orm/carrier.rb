module Transponder
  module ORM
    class Carrier < Base
      class << self
        def all
          reset if @memo_expires_at&.past?

          @all ||= Collection.new(self, fetch.map { |attributes| new(**attributes) }).tap { @memo_expires_at = MEMO_EXPIRES_IN.from_now }
        end

        def primary_key = :id

        private

        def fetch
          Rails.cache.fetch("transponder@#{ORM.version}/carriers", expires_in: CACHE_EXPIRES_IN) do
            response = GraphQLClient::Transponder::Client.query(GraphQLClient::Transponder::Query::FetchCarriers::DETAILS)
            errors = response.original_hash['errors']
            raise GraphQL::Client::Error, errors.pluck('message').join(', ') if errors.present?

            response
              .original_hash
              .dig('data', 'fetchCarriers')
              .map { |carrier| carrier.deep_transform_keys { |key| key.underscore.to_sym } }
          end
        end
      end

      CACHE_EXPIRES_IN = 1.day
      MEMO_EXPIRES_IN = 1.hour

      attr_reader :check_mailing_addresses,
                  :contacts,
                  :headquarters,
                  :id,
                  :lanes,
                  :legal_name,
                  :required_credential_types,
                  :scac,
                  :terminals,
                  :territories,
                  :us_dot_number,
                  :us_mc_number,
                  :valid_tracking_number_pattern,
                  :website_url

      def initialize( # rubocop:disable Metrics/ParameterLists
        id:,
        acts_as_broker: false,
        bol_requires_tracking_number: false,
        check_mailing_addresses: [],
        consider_bol_and_pod_documents_same: false,
        contacts: [],
        create_pickup_implemented: false,
        find_rates_implemented: false,
        find_rates_with_declared_value: false,
        headquarters: nil,
        lanes: [],
        legal_name: nil,
        name: nil,
        pickup_number_is_tracking_number: false,
        rates_with_excessive_length_fees: false,
        required_credential_types: [],
        scac: nil,
        terminals: [],
        territories: [],
        us_dot_number: nil,
        us_mc_number: nil,
        valid_tracking_number_pattern: nil,
        website_url: nil
      )
        super()

        @acts_as_broker = acts_as_broker
        @bol_requires_tracking_number = bol_requires_tracking_number
        @check_mailing_addresses = check_mailing_addresses.map { |address| CarrierAddress.new(**address) }
        @consider_bol_and_pod_documents_same = consider_bol_and_pod_documents_same
        @contacts = contacts.map { |contact| CarrierContact.new(**contact) }
        @create_pickup_implemented = create_pickup_implemented
        @find_rates_implemented = find_rates_implemented
        @find_rates_with_declared_value = find_rates_with_declared_value
        @headquarters = CarrierAddress.new(**headquarters) if headquarters.present?
        @id = id
        @lanes = lanes.map { |lane| Lane.new(**lane, carrier: self) }
        @legal_name = legal_name
        @name = name
        @pickup_number_is_tracking_number = pickup_number_is_tracking_number
        @rates_with_excessive_length_fees = rates_with_excessive_length_fees
        @required_credential_types = required_credential_types.map(&:to_sym)
        @scac = scac
        @terminals = terminals.map { |terminal| Terminal.new(**terminal, carrier: self) }
        @territories = territories.map { |territory| Territory.new(**territory) }
        @us_dot_number = us_dot_number
        @us_mc_number = us_mc_number
        @valid_tracking_number_pattern = Regexp.new(valid_tracking_number_pattern) if valid_tracking_number_pattern.present?
        @website_url = website_url if website_url.to_s.match?(%r{\Ahttps?://}i)
      end

      def acts_as_broker? = @acts_as_broker
      def addresses = [headquarters, *check_mailing_addresses, *terminals.map(&:address)].compact
      def api? = required_credential_types.any?
      def bol_requires_tracking_number? = @bol_requires_tracking_number
      def consider_bol_and_pod_documents_same? = @consider_bol_and_pod_documents_same
      def create_pickup_implemented? = @create_pickup_implemented
      def find_rates_implemented? = @find_rates_implemented
      def find_rates_with_declared_value? = @find_rates_with_declared_value

      def matching_lanes(destination:, origin:)
        lane_ids = fetch_coverage(GraphQLClient::Transponder::Query::FetchMatchingLanes::DETAILS, destination:, origin:)['matchingLanes']
        lanes.index_by(&:id).values_at(*lane_ids.to_a.pluck('id')).compact
      end

      def name = @name || id
      def pickup_number_is_tracking_number? = @pickup_number_is_tracking_number
      def rates_with_excessive_length_fees? = @rates_with_excessive_length_fees

      def serve?(destination:, origin:)
        fetch_coverage(GraphQLClient::Transponder::Query::FetchServe::DETAILS, destination:, origin:)['serve'] == true
      end

      def valid_tracking_number?(number) = valid_tracking_number_pattern.blank? || valid_tracking_number_pattern.match?(number.to_s)

      private

      def fetch_coverage(query, destination:, origin:)
        response = GraphQLClient::Transponder::Client.query(
          query,
          variables: { destination: destination.to_transponder_graphql_input, id:, origin: origin.to_transponder_graphql_input }
        )
        errors = response.original_hash['errors']
        raise GraphQL::Client::Error, errors.pluck('message').join(', ') if errors.present?

        response.original_hash.dig('data', 'fetchCarriers', 0).to_h
      end
    end
  end
end
