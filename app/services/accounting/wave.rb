module Accounting
  module Wave
    class << self
      def address_from(address)
        address.presence && Address.new(
          city: address['city'],
          country: address.dig('country', 'code'),
          line1: address['addressLine1'],
          line2: address['addressLine2'],
          postal_code: address['postalCode'],
          region: address.dig('province', 'code')&.split('-')&.last
        )
      end

      def address_input(address)
        address && {
          addressLine1: address.line1,
          addressLine2: address.line2,
          city: address.city,
          countryCode: address.country,
          postalCode: address.postal_code,
          provinceCode: ("#{address.country}-#{address.region}" if address.country.present? && address.region.present?)
        }.compact.presence
      end
    end
  end
end
