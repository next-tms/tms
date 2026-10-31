module Accounting
  module Wave
    class << self
      def address_from(address)
        return if address.blank?

        Address.new(
          city: address['city'],
          line1: address['addressLine1'],
          line2: address['addressLine2'],
          postal_code: address['postalCode']
        )
      end

      def address_input(address)
        return if address.nil?

        { addressLine1: address.line1, addressLine2: address.line2, city: address.city, postalCode: address.postal_code }.compact.presence
      end
    end
  end
end
