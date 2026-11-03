module Accounting
  module Wave
    class Customer < Accounting::Customer
      class << self
        def attributes_from(node)
          {
            billing_address: Wave.address_from(node['address']),
            company_name: node['name'],
            display_name: node['name']
          }
        end

        def collection_key = 'customers'
        def connection = @connection ||= Connection.new(self)

        def create_input(customer, business_id)
          { address: Wave.address_input(customer.billing_address), businessId: business_id, name: name_for(customer) }.compact
        end

        def create_mutation = 'customerCreate'
        def delete_mutation = 'customerDelete'
        def list_arguments = 'sort: [NAME_ASC]'
        def match?(node, field, value) = node[field.to_s] == value
        def node_key = 'customer'

        def patch_input(customer)
          { address: Wave.address_input(customer.billing_address), id: customer.id, name: name_for(customer) }.compact
        end

        def patch_mutation = 'customerPatch'
        def selection = SELECTION

        private

        def name_for(customer) = customer.display_name.presence || customer.company_name
      end

      SELECTION = 'id name address { addressLine1 addressLine2 city country { code } postalCode province { code } }'.freeze
    end
  end
end
