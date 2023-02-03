require 'graphql/client'

# Graphql Custom Client
# Use Duck Typing to extend library instance methods and bind logger
class GraphqlClient::CustomClient < GraphQL::Client
  def initialize(schema:, execute: nil, enforce_collocated_callers: false)
    super(
      schema: schema,
      execute: execute,
      enforce_collocated_callers: enforce_collocated_callers
    )
  end

  def query(definition, variables: {})
    body = {
      'query': definition.document.to_query_string,
      'variables': variables.inspect,
      'operationName': definition.operation_name
    }

    Rails.logger.debug("[GraphqlClient] Query String: #{body.to_json}\n")

    super(definition, variables: variables)
  end
end
