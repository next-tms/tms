module Tools
  class GraphQLQuery < BaseTool
    tool_name 'graphql_query'
    description 'Run a read-only GraphQL query against the TMS API. Call graphql_schema first for the types and fields your role can use.'
    annotations(destructive_hint: false, idempotent_hint: true, open_world_hint: false, read_only_hint: true)
    input_schema(
      properties: {
        operation_name: { description: 'Name of the operation to run when the query defines more than one', type: 'string' },
        query: { description: 'GraphQL query document', type: 'string' },
        variables: { description: 'GraphQL variables keyed by variable name', type: 'object' }
      },
      required: ['query']
    )

    class << self
      def call(query:, server_context:, operation_name: nil, variables: {})
        return MCP::Tool::Response.new([{ text: READ_ONLY_ERROR, type: 'text' }], error: true) unless read_only?(query, operation_name:)

        execute(query, context: server_context.slice(:authorizable, :session), operation_name:, variables: variables.deep_stringify_keys)
      end

      def read_only?(query, operation_name:)
        [nil, 'query'].include?(GraphQL::Query.new(TMSSchema, query, operation_name:).selected_operation&.operation_type)
      end
    end

    READ_ONLY_ERROR = 'Only query operations are allowed. Use create_quote, create_shipment, or fetch_rates to change data.'.freeze
  end
end
