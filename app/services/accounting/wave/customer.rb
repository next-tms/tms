module Accounting
  module Wave
    class Customer < Accounting::Customer
      SELECTION = 'id name address { addressLine1 addressLine2 city postalCode }'.freeze

      class << self
        def attributes_from(node)
          { billing_address: Wave.address_from(node['address']), company_name: node['name'], display_name: node['name'] }
        end

        def collection_key = 'customers'
        def connection = @connection ||= Connection.new(self)
        def create_input(customer, business_id) = { businessId: business_id, name: name_for(customer), address: Wave.address_input(customer.billing_address) }.compact
        def create_mutation = 'customerCreate'
        def delete_mutation = 'customerDelete'
        def list_arguments = 'sort: [NAME_ASC]'
        def match?(node, field, value) = node[field.to_s] == value
        def node_key = 'customer'
        def patch_input(customer) = { id: customer.id, name: name_for(customer), address: Wave.address_input(customer.billing_address) }.compact
        def patch_mutation = 'customerPatch'
        def selection = SELECTION

        private

        def name_for(customer) = customer.display_name.presence || customer.company_name
      end
    end
  end
end
