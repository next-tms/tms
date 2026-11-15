require 'graphql/client'

module GraphQLClient
  class Grid
    class HTTPAdapter
      def execute(document:, context: {}, operation_name: nil, variables: {}) # rubocop:disable Lint/UnusedMethodArgument
        json = { operationName: operation_name, query: document.to_query_string, variables: variables.presence }.compact

        JSON.parse(CompressedHTTPClient.post(ENV.fetch('GRID_URL'), json:, timeout: Geo::Provider::TIMEOUT).body.read)
      end
    end

    SCHEMA_PATH = Rails.root.join('schemas/grid.json').to_s

    Schema = GraphQL::Client.load_schema(SCHEMA_PATH)
    Client = GraphQL::Client.new(execute: HTTPAdapter.new, schema: Schema)
  end
end
