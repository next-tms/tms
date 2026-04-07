require 'graphql/client'
require 'graphql/client/http'

module GraphQLClient
  class Transponder
    ENDPOINT = ENV.fetch('TRANSPONDER_URL', 'http://localhost:2300/graphql')
    SCHEMA_PATH = Rails.root.join('schemas/transponder.json').to_s

    HTTP = GraphQL::Client::HTTP.new(ENDPOINT)
    Schema = GraphQL::Client.load_schema(SCHEMA_PATH)

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end
end
