module TransponderService
  module Input
    class Location < Base
      attr_reader :attribute_prefix, :contactable

      def initialize(object, contactable:, attribute_prefix: nil)
        @attribute_prefix = attribute_prefix
        @contactable = contactable

        super
      end

      def build
        {
          address1: object.street,
          city: object.city,
          contact:,
          country: {
            alpha3: object.country.alpha3_code
          },
          postal_code: object.zip_code,
          region_abbreviation: object.region.abbreviation
        }
      end

      private

      def contact
        return if contactable.blank?

        Contact.call(contactable, attribute_prefix:)
      end
    end
  end
end
