module Accounting
  module Wave
    class Vendor < Accounting::Vendor
      SELECTION = 'id name address { addressLine1 addressLine2 city postalCode }'.freeze

      class << self
        def attributes_from(node)
          { billing_address: Wave.address_from(node['address']), company_name: node['name'], display_name: node['name'] }
        end

        def collection_key = 'vendors'
        def connection = @connection ||= Connection.new(self)
        def list_arguments = ''
        def match?(node, field, value) = node[field.to_s] == value
        def node_key = 'vendor'
        def selection = SELECTION
      end
    end
  end
end
