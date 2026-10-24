module FreightKitAPIClient
  module Services
    class BuildAPIClient
      def self.call(broker_carrier:)
        return if broker_carrier.carrier&.scac.blank?

        freight_kit_class = broker_carrier.carrier.freight_kit_class
        return if freight_kit_class.blank?

        credentials = build_credentials(broker_carrier:)
        customer_location = build_customer_location
        tariff = broker_carrier.to_freight_kit_tariff

        begin
          freight_kit_class.new(credentials, customer_location:, tariff:)
        rescue ArgumentError => e
          raise e unless e.message.include?('`Credential` of type(s) missing:')

          # Return nil if no api or website credentials found
        end
      end

      def self.build_customer_location
        address = Setting.mailing_address!

        FreightKit::Location.new(
          contact: FreightKit::Contact.new(company_name: Setting.value!(:name), email: "robot@#{Setting.customer_service_email!.split("@")[1]}"),
          address1: address.street.sub('Apt', 'Ste'),
          city: address.city,
          postal_code: address.zip_code,
          province: address.region.abbreviation,
          country: ActiveUtils::Country.find(address.country.alpha2_code),
        )
      end

      def self.build_credentials(broker_carrier:)
        required_credential_types = broker_carrier.carrier.required_freight_kit_credentials
        required_credential_types.map { |type| BuildFreightKitCredential.new(type:, broker_carrier:).call }.compact
      end
    end
  end
end
