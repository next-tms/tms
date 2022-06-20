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

        customer_location = broker_carrier.broker.as_interstellar_location
        credentials = build_credentials(broker_carrier:)
        tariff = broker_carrier.to_interstellar_tariff

        carrier.new(credentials, customer_location:, tariff:)
      end

      def self.build_credentials(broker_carrier:)
        [
          BuildInterstellarCredential.new(type: :api, broker_carrier: broker_carrier).call,
          BuildInterstellarCredential.new(type: :selenoid).call,
          BuildInterstellarCredential.new(type: :website, broker_carrier: broker_carrier).call
        ]
      end
    end
  end
end
