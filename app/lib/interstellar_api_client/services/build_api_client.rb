# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class BuildApiClient
      def self.call(broker_carrier:)
        return nil if broker_carrier.carrier&.scac.blank?

        carrier = begin
          Interstellar.const_get(broker_carrier.carrier.scac)
        rescue NameError
          nil
        end

        return nil if carrier.blank?

        credentials = [
          Interstellar::Credential.new(
            type: :api,
            account: broker_carrier.account,
            username: broker_carrier.username,
            password: broker_carrier.password
          ),
          Interstellar::Credential.new(
            type: :selenoid,
            base_url: URI.parse(ENV['SELENOID_BASE_URL']),
            browser: :chrome
          )
        ]

        credentials << if broker_carrier.carrier.has_seperate_website_credentials?
                         Interstellar::Credential.new(
                           type: :website,
                           username: broker_carrier.website_username,
                           password: broker_carrier.website_password
                         )
                       else
                         Interstellar::Credential.new(
                           type: :website,
                           account: broker_carrier.account,
                           username: broker_carrier.username,
                           password: broker_carrier.password
                         )
                       end

        customer_location = broker_carrier.broker.as_interstellar_location
        tariff = broker_carrier.to_interstellar_tariff

        carrier.new(credentials, customer_location:, tariff:)
      end
    end
  end
end
