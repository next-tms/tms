# frozen_string_literal: true

module FreightKitAPIClient
  module Services
    class BuildFreightKitCredential
      def initialize(type:, broker_carrier: nil, return_hash: false)
        @type = type.to_sym
        @broker_carrier = broker_carrier
        @return_hash = return_hash
      end

      def call
        return if %i[api api_key api_proxy selenoid website].exclude?(type)

        creds = send("#{type}_credentials")
        return creds if @return_hash

        FreightKit::Credential.new(**creds)
      end

      private

      attr_reader :type, :broker_carrier

      # @note Okay to pass blank `FreightKit::Credential` attributes
      def api_credentials
        {
          type: :api,
          account: broker_carrier.account,
          api_key:,
          username: broker_carrier.username,
          password: broker_carrier.password
        }
      end

      # `FreightKit::Credential` with only `#api_key`, `#proxy_url` attributes
      def api_proxy_credentials
        {
          type: :api_proxy,
          proxy_url: broker_carrier.carrier.encrypted_proxy_url,
          api_key:
        }
      end

      # `FreightKit::Credential` with only `#api_key`, `#account` attributes
      def api_key_credentials
        {
          type: :api_key,
          account: broker_carrier.account,
          api_key:
        }
      end

      def selenoid_credentials
        {
          type: :selenoid,
          base_url: URI.parse(ENV.fetch('SELENOID_BASE_URL')),
          browser: :chrome
        }
      end

      def website_credentials
        return if [ broker_carrier.website_username, broker_carrier.website_password ].any?(&:blank?)

        {
          type: :website,
          account: broker_carrier.account,
          username: broker_carrier.website_username,
          password: broker_carrier.website_password
        }
      end

      def api_key
        broker_carrier.carrier.encrypted_api_key.presence || broker_carrier.encrypted_api_key
      end
    end
  end
end
