# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class BuildInterstellarCredential
      def initialize(type:, broker_carrier: nil)
        @type = type.to_sym
        @broker_carrier = broker_carrier
      end

      def call
        case type
        when :api then api_credentials
        when :selenoid then selenoid_credentials
        when :website then website_credentials
        end
      end

      private

      attr_reader :type, :broker_carrier

      def api_credentials
        return nil if [broker_carrier.account, broker_carrier.username, broker_carrier.password].any?(&:blank?)

        Interstellar::Credential.new(
          type: :api,
          account: broker_carrier.account,
          api_key: broker_carrier.carrier.encrypted_api_key,
          username: broker_carrier.username,
          password: broker_carrier.password
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
        if broker_carrier.carrier.has_seperate_website_credentials?
          return nil if [broker_carrier.website_username, broker_carrier.website_password].any?(&:blank?)

          Interstellar::Credential.new(
            type: :website,
            username: broker_carrier.website_username,
            password: broker_carrier.website_password
          )
        else
          Interstellar::Credential.new(
            return nil if [broker_carrier.account, broker_carrier.username, broker_carrier.password].any?(&:blank?)

            type: :website,
            account: broker_carrier.account,
            username: broker_carrier.username,
            password: broker_carrier.password
          )
        end
      end
    end
  end
end
