module Accounting
  module QuickBooks
    class << self
      def physical_address(address)
        return if address.nil?

        ::Quickbooks::Model::PhysicalAddress.new(
          city: address.city,
          country_sub_division_code: address.region,
          line1: address.line1,
          line2: address.line2,
          postal_code: address.postal_code,
        )
      end
    end
  end
end
