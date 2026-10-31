module TransponderService
  module Input
    class Carrier < Base
      def build
        {
          carrier_credentials:,
          customer_location:,
          scac: object.scac.presence,
          tariff:
        }
      end

      private

      def api_credential
        {
          account: object.account,
          api_key: object.carrier.encrypted_api_key.presence || object.encrypted_api_key,
          username: object.username,
          password: object.password,
          type: 'api'
        }.compact_blank
      end

      def api_key_credential
        {
          account: object.account,
          api_key: object.carrier.encrypted_api_key.presence || object.encrypted_api_key,
          type: 'api_key'
        }.compact_blank
      end

      def api_proxy_credential
        return if object.carrier.encrypted_proxy_url.blank?

        {
          type: 'api_proxy',
          proxy_url: object.carrier.encrypted_proxy_url,
          api_key: object.carrier.encrypted_api_key.presence || object.encrypted_api_key
        }.compact_blank
      end

      def carrier_credentials
        object.carrier.required_freight_kit_credentials.map { |type| __send__("#{type}_credential") }.compact
      end

      def customer_location
        setting = ::Setting.find_by!(key: 'mailing_address')

        Location.call(setting.value, contactable: setting)
      end

      # @note :base_url, :browser handled upstream by Transponder
      def selenoid_credential
        { type: 'selenoid' }
      end

      def tariff
        Tariff.call(object)
      end

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
