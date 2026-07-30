module Accounting
  module Wave
    class Connection
      PAGE_SIZE = 200

      attr_reader :record_class

      def initialize(record_class) = @record_class = record_class

      def all(page: nil, page_size: nil, **)
        list_page(page || 1, page_size: page_size || PAGE_SIZE)['edges'].map { |edge| build(edge['node']) }
      end

      def create(record)
        raise UnsupportedResource, record_class.name unless record_class.respond_to?(:create_mutation)

        build(mutate(record_class.create_mutation, record_class.create_input(record, business_id)))
      end

      def destroy(record)
        raise UnsupportedResource, record_class.name unless record_class.respond_to?(:delete_mutation)

        mutation = record_class.delete_mutation
        result = execute(delete_query(mutation), input: { id: record.id }).fetch(mutation)
        raise Error, mutation_error(result) unless result['didSucceed']

        true
      end

      def find(id)
        build(execute(find_query, businessId: business_id, id:).dig('business', record_class.node_key))
      end

      def find_by(conditions)
        field, value = conditions.first
        build(each_node.find { |node| record_class.match?(node, field, value) })
      end

      def update(record)
        raise UnsupportedResource, record_class.name unless record_class.respond_to?(:patch_mutation)

        build(mutate(record_class.patch_mutation, record_class.patch_input(record)))
      end

      private

      def authenticator = Accounting.integration.service
      def build(node) = node.present? ? record_class.new(node['id'], loaded: true, **record_class.attributes_from(node)) : nil
      def business_id = authenticator.business_id

      def delete_query(mutation)
        "mutation Delete($input: #{mutation.camelize}Input!) { #{mutation}(input: $input) { didSucceed inputErrors { code message path } } }"
      end

      def each_node
        return enum_for(:each_node) unless block_given?

        page = 1

        loop do
          collection = list_page(page)
          collection['edges'].each { |edge| yield edge['node'] }
          break if page >= collection.dig('pageInfo', 'totalPages').to_i

          page += 1
        end
      end

      def execute(query, **variables) = authenticator.graphql(query, **variables)

      def find_query
        "query Find($businessId: ID!, $id: ID!) { business(id: $businessId) { #{record_class.node_key}(id: $id) { #{record_class.selection} } } }"
      end

      def list_page(page, page_size: PAGE_SIZE)
        arguments = [ 'page: $page', 'pageSize: $pageSize', record_class.list_arguments.presence ].compact.join(', ')
        query = "query List($businessId: ID!, $page: Int!, $pageSize: Int!) { business(id: $businessId) { #{record_class.collection_key}(#{arguments}) { pageInfo { totalPages } edges { node { #{record_class.selection} } } } } }"

        execute(query, businessId: business_id, page:, pageSize: page_size).dig('business', record_class.collection_key)
      end

      def mutate(mutation, input)
        query = "mutation Mutate($input: #{mutation.camelize}Input!) { #{mutation}(input: $input) { didSucceed inputErrors { code message path } #{record_class.node_key} { #{record_class.selection} } } }"
        result = execute(query, input:).fetch(mutation)
        raise Error, mutation_error(result) unless result['didSucceed']

        result[record_class.node_key]
      end

      def mutation_error(result)
        Array(result['inputErrors']).map { |error| [ error['path']&.join('.'), error['message'] ].compact.join(': ') }.join('; ')
      end
    end
  end
end
