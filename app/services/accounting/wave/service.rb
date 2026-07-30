module Accounting
  module Wave
    class Service
      GRAPHQL_URL = 'https://gql.waveapps.com/graphql/public'.freeze
      MAX_AUTH_ATTEMPTS = 3
      REQUIRED_CREDENTIALS = %i[access_token business_id].freeze
      SCOPE = 'account:* business:* customer:* invoice:* product:* sales_tax:* transaction:* vendor:*'.freeze

      attr_reader :integration

      def initialize(integration) = @integration = integration

      def authorize_url(redirect_uri:, state:)
        oauth_client.auth_code.authorize_url(redirect_uri:, response_type: 'code', scope: SCOPE, state:)
      end

      def connect!(code:, redirect_uri:, **)
        response = oauth_client.auth_code.get_token(code, redirect_uri:)
        raise 'Accounting::Wave::Service::ConnectionFailed' unless response

        integration.update!(
          credentials: {
            access_token: response.token,
            access_token_expires_at: (Time.at(response.expires_at) if response.expires_at),
            business_id: default_business_id(response),
            refresh_token: response.refresh_token
          },
        )
      end

      def connect_with_token!(access_token:)
        business_id = default_business_id(OAuth2::AccessToken.new(oauth_client, access_token))
        integration.update!(credentials: { access_token:, business_id: })
      end

      def connected? = credentials[:access_token].present?

      def graphql(query, **variables)
        response = perform_authenticated_request do |access_token|
          access_token.post(GRAPHQL_URL, headers: { 'Content-Type' => 'application/json' }, body: { query:, variables: }.to_json)
        end

        parsed = response.parsed
        raise Error, Array(parsed['errors']).filter_map { |error| error['message'] }.join('; ') if parsed['errors'].present?

        parsed.fetch('data')
      end

      def perform_authenticated_request
        attempts = 0

        begin
          integration.reload
          yield access_token
        rescue OAuth2::Error
          raise if credentials[:refresh_token].blank?

          attempts += 1
          raise 'Accounting::Wave::Service::ExceededAuthAttempts' if attempts >= MAX_AUTH_ATTEMPTS

          sleep(1)
          refresh!
          retry
        end
      end

      def business_id = credentials[:business_id]

      def validate_credentials
        missing = REQUIRED_CREDENTIALS.select { |key| credentials[key].blank? }
        integration.errors.add(:credentials, "is missing #{missing.join(', ')}") if missing.any?
      end

      private

      def access_token = OAuth2::AccessToken.new(oauth_client, credentials[:access_token], refresh_token: credentials[:refresh_token])
      def credentials = integration.credentials.to_h.symbolize_keys

      def default_business_id(access_token)
        query = 'query { businesses(page: 1, pageSize: 1) { edges { node { id } } } }'
        response = access_token.post(GRAPHQL_URL, headers: { 'Content-Type' => 'application/json' }, body: { query: }.to_json)
        response.parsed.dig('data', 'businesses', 'edges', 0, 'node', 'id')
      end

      def oauth_client
        OAuth2::Client.new(
          ENV.fetch('WAVE_CLIENT_ID'),
          ENV.fetch('WAVE_CLIENT_SECRET'),
          authorize_url: 'https://api.waveapps.com/oauth2/authorize/',
          site: 'https://api.waveapps.com',
          token_url: 'https://api.waveapps.com/oauth2/token/',
        )
      end

      def refresh!
        refreshed = access_token.refresh!

        integration.update!(
          credentials: credentials.merge(
            access_token: refreshed.token,
            access_token_expires_at: (Time.at(refreshed.expires_at) if refreshed.expires_at),
            refresh_token: refreshed.refresh_token,
          ),
        )
      end
    end
  end
end
