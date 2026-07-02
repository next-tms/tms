module Accounting
  module QuickBooks
    class Customer < Accounting::Customer
      class << self
        def attributes_from(customer)
          { company_name: customer.company_name, display_name: customer.display_name }
        end

        def connection = @connection ||= Connection.new(self)
        def find_field(attribute) = { name: :company_name }.fetch(attribute, attribute)

        def serialize(customer, model = nil)
          model ||= ::Quickbooks::Model::Customer.new
          model.billing_address = QuickBooks.physical_address(customer.billing_address)
          model.company_name = customer.company_name
          model.display_name = customer.display_name
          model.shipping_address = QuickBooks.physical_address(customer.shipping_address)
          model
        end

        def service_class = ::Quickbooks::Service::Customer
      end
    end
  end
end
