# frozen_string_literal: true

module InterstellarAPIClient
  module Services
    class BuildInterstellarCredential
      def initialize(type:, broker_carrier: nil)
        @type = type.to_sym
        @broker_carrier = broker_carrier
      end

      def call
        return nil if %i[api api_key api_proxy selenoid website].exclude?(type)

        send("#{type}_credentials")
      end

      private

      attr_reader :type, :broker_carrier

      # @note Okay to pass blank `Interstellar::Credential` attributes
      def api_credentials
        Interstellar::Credential.new(
          type: :api,
          account: broker_carrier.account,
          api_key:,
          username: broker_carrier.username,
          password: broker_carrier.password
        )
      end

      # `Interstellar::Credential` with only `#api_key`, `#proxy_url` attributes
      def api_proxy_credentials
        Interstellar::Credential.new(
          type: :api_proxy,
          proxy_url: broker_carrier.carrier.encrypted_proxy_url,
          api_key:,
        )
      end

      # `Interstellar::Credential` with only `#api_key`, `#account` attributes
      def api_key_credentials
        Interstellar::Credential.new(
          type: :api_key,
          account: broker_carrier.account,
          api_key:,
        )
      end

      def selenoid_credentials
        Interstellar::Credential.new(
          type: :selenoid,
          base_url: URI.parse(Rails.application.credentials.selenoid.base_url),
          browser: :chrome
        )
      end

      def website_credentials
        return nil if [broker_carrier.website_username, broker_carrier.website_password].any?(&:blank?)

        Interstellar::Credential.new(
          type: :website,
          username: broker_carrier.website_username,
          password: broker_carrier.website_password
        )
      end

      def api_key
        broker_carrier.carrier.encrypted_api_key.presence || broker_carrier.encrypted_api_key
      end
    end
  end
end
