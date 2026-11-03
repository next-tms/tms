module Accounting
  module QuickBooks
    class Vendor < Accounting::Vendor
      class << self
        def attributes_from(vendor)
          {
            billing_address: QuickBooks.address_from(vendor.billing_address),
            company_name: vendor.company_name,
            display_name: vendor.display_name
          }
        end

        def connection = @connection ||= Connection.new(self)
        def find_field(attribute) = { name: :company_name }.fetch(attribute, attribute)

        def serialize(vendor, model = nil)
          model ||= ::Quickbooks::Model::Vendor.new
          model.billing_address = QuickBooks.physical_address(vendor.billing_address)
          model.company_name = vendor.company_name
          model.display_name = vendor.display_name
          model
        end

        def service_class = ::Quickbooks::Service::Vendor
      end
    end
  end
end
