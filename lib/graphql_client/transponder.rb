require "graphql/client"
require "graphql/client/http"

module GraphqlClient
  class Transponder
    # Configure GraphQL endpoint using the basic HTTP network adapter.
    endpoint = ENV.fetch("TRANSPONDER_URL", 'http://localhost:2300/graphql')

    HTTP = GraphQL::Client::HTTP.new(endpoint)

    # Fetch latest schema on init, this will make a network request
    # Schema = GraphQL::Client.load_schema(HTTP)

    # Run it from a script or rake task to populate schema.json
    #   GraphQL::Client.dump_schema(HTTP, "lib/graphql/schema.json")

    # # However, it's smart to dump this to a JSON file and load from disk
    schema_path = "lib/graphql/schema.json"
    Schema = GraphQL::Client.load_schema(schema_path)

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end
end
