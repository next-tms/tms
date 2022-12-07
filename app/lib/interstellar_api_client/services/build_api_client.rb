# frozen_string_literal: true

module InterstellarAPIClient
  module Services
    class BuildAPIClient
      def self.call(broker_carrier:)
        return nil if broker_carrier.carrier&.scac.blank?

        interstellar_class = broker_carrier.carrier.interstellar_class
        return nil if interstellar_class.blank?

        credentials = build_credentials(broker_carrier:)
        customer_location = broker_carrier.broker.as_interstellar_location
        tariff = broker_carrier.to_interstellar_tariff

        begin
          interstellar_class.new(credentials, customer_location:, tariff:)
        rescue ArgumentError => e
          raise e unless e.message.include?('`Credential` of type(s) missing:')

          # Return nil if no api or website credentials found
        end
      end

      def self.build_credentials(broker_carrier:)
        required_credential_types =  broker_carrier.carrier.required_interstellar_credentials
        required_credential_types.map { |type| BuildInterstellarCredential.new(type:, broker_carrier:).call }.compact
      end
    end
  end
end
