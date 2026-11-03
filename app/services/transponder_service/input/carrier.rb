module TransponderService
  module Input
    class Carrier < Base
      def build = { carrier_credentials:, customer_location:, scac: object.scac.presence, tariff: }

      private

      def api_credential
        {
          account: object.account,
          api_key: object.encrypted_api_key,
          username: object.username,
          password: object.password,
          type: 'api'
        }.compact_blank
      end

      def api_key_credential = { account: object.account, api_key: object.encrypted_api_key, type: 'api_key' }.compact_blank
      def api_proxy_credential = { api_key: object.encrypted_api_key, type: 'api_proxy' }.compact_blank
      def carrier_credentials = object.carrier.required_credential_types.map { |type| __send__("#{type}_credential") }

      def customer_location
        setting = ::Setting.find_by!(key: 'mailing_address')

        Location.call(setting.value, contactable: setting)
      end

      def selenoid_credential = { type: 'selenoid' }
      def tariff = Tariff.call(object)

      def website_credential
        {
          account: object.account,
          username: object.website_username,
          password: object.website_password,
          type: 'website'
        }
      end
    end
  end
end
