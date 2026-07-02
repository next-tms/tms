module Accounting
  module QuickBooks
    class Service
      MAX_AUTH_ATTEMPTS = 3
      REQUIRED_CREDENTIALS = %i[access_token realm_id refresh_token].freeze

      attr_reader :integration

      def initialize(integration) = @integration = integration

      def authorize_url(redirect_uri:, state:)
        oauth_client.auth_code.authorize_url(redirect_uri:, response_type: 'code', scope: 'com.intuit.quickbooks.accounting', state:)
      end

      def connect!(code:, realm_id:, redirect_uri:)
        response = oauth_client.auth_code.get_token(code, redirect_uri:)
        raise 'Accounting::QuickBooks::Service::ConnectionFailed' unless response

        integration.update!(
          credentials: {
            access_token: response.token,
            access_token_expires_at: (Time.at(response.expires_at) if response.expires_at),
            realm_id:,
            refresh_token: response.refresh_token
          },
        )
      end

      def connected? = credentials[:refresh_token].present?

      def perform_authenticated_request
        attempts = 0

        begin
          integration.reload
          yield access_token
        rescue OAuth2::Error, ::Quickbooks::AuthorizationFailure
          attempts += 1
          raise 'Accounting::QuickBooks::Service::ExceededAuthAttempts' if attempts >= MAX_AUTH_ATTEMPTS

          sleep(1)
          refresh!
          retry
        end
      end

      def realm_id = credentials[:realm_id]

      def validate_credentials
        missing = REQUIRED_CREDENTIALS.select { |key| credentials[key].blank? }
        integration.errors.add(:credentials, "is missing #{missing.join(', ')}") if missing.any?
      end

      private

      def access_token = OAuth2::AccessToken.new(oauth_client, credentials[:access_token], refresh_token: credentials[:refresh_token])
      def credentials = integration.credentials.to_h.symbolize_keys

      def oauth_client
        OAuth2::Client.new(
          ENV.fetch('INTUIT_CLIENT_ID'),
          ENV.fetch('INTUIT_CLIENT_SECRET'),
          authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
          site: 'https://appcenter.intuit.com/connect/oauth2',
          token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer',
        )
      end

      def refresh!
        refreshed = access_token.refresh!
        expires_in = refreshed.params['x_refresh_token_expires_in'].to_i

        integration.update!(
          credentials: credentials.merge(
            access_token: refreshed.token,
            access_token_expires_at: Time.at(refreshed.expires_at),
            refresh_token: refreshed.refresh_token,
            refresh_token_expires_at: expires_in.positive? ? Time.now + expires_in.seconds : 100.days.from_now,
          ),
        )
      end
    end
  end
end
