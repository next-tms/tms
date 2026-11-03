module Accounting
  module QuickBooks
    class << self
      def address_from(physical_address)
        physical_address && Address.new(
          city: physical_address.city,
          country: physical_address.country,
          line1: physical_address.line1,
          line2: physical_address.line2,
          postal_code: physical_address.postal_code,
          region: physical_address.country_sub_division_code
        )
      end

      def physical_address(address)
        address && ::Quickbooks::Model::PhysicalAddress.new(
          city: address.city,
          country: address.country,
          country_sub_division_code: address.region,
          line1: address.line1,
          line2: address.line2,
          postal_code: address.postal_code
        )
      end
    end
  end
end
