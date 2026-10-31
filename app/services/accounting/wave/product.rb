module Accounting
  module Wave
    class Product
      INCOME_SUBTYPES = ['INCOME', 'OTHER_INCOME'].freeze
      NAME = 'Freight'.freeze

      class << self
        def id
          integration = Accounting.integration
          credentials = integration.credentials.to_h.symbolize_keys
          return credentials[:product_id] if credentials[:product_id].present?

          product_id = find || create
          integration.update!(credentials: credentials.merge(product_id:))
          product_id
        end

        private

        def business_id = service.business_id

        def create
          input = { businessId: business_id, incomeAccountId: income_account_id, name: NAME, unitPrice: 0 }
          result = service.graphql(<<~GQL, input:).fetch('productCreate')
            mutation Create($input: ProductCreateInput!) { productCreate(input: $input) { didSucceed inputErrors { message path } product { id } } }
          GQL
          raise Error, Array(result['inputErrors']).pluck('message').join('; ') unless result['didSucceed']

          result.dig('product', 'id')
        end

        def find
          nodes = service.graphql(<<~GQL, businessId: business_id).dig('business', 'products', 'edges').pluck('node')
            query List($businessId: ID!) { business(id: $businessId) { products(page: 1, pageSize: 100) { edges { node { id name isArchived isSold } } } } }
          GQL
          node = nodes.find { |candidate| candidate['name'] == NAME && !candidate['isArchived'] }
          node ||= nodes.find { |candidate| candidate['isSold'] && !candidate['isArchived'] }
          node&.fetch('id')
        end

        def income_account_id
          nodes = service.graphql(<<~GQL, businessId: business_id).dig('business', 'accounts', 'edges').pluck('node')
            query Accounts($businessId: ID!) { business(id: $businessId) { accounts(page: 1, pageSize: 50, types: [INCOME]) { edges { node { id subtype { value } } } } } }
          GQL
          node = INCOME_SUBTYPES.filter_map { |subtype| nodes.find { |candidate| candidate.dig('subtype', 'value') == subtype } }.first
          node&.fetch('id')
        end

        def service = Accounting.integration.service
      end
    end
  end
end
