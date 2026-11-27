require 'graphql/client'
require 'graphql/client/http'

module GraphQLClient
  class Transponder
    class << self
      def endpoint
        @endpoint ||= begin
          value = uri
          value.password = nil
          value.user = nil
          value.to_s
        end
      end

      def uri = URI.parse(ENV.fetch('TRANSPONDER_URL'))
    end

    class HTTPAdapter < GraphQL::Client::HTTP
      TIMEOUT = { connect_timeout: 5, total_request_timeout: 150 }.freeze

      def execute(document:, context: {}, operation_name: nil, variables: {}) # rubocop:disable Lint/UnusedMethodArgument
        json = { query: document.to_query_string }
        json[:operationName] = operation_name if operation_name.present?
        json[:variables] = variables if variables.present?

        response = http_client.post(Transponder.endpoint, json:)
        JSON.parse(response.body.read)
      rescue HTTPX::HTTPError => e
        raise GraphQL::Client::Error, "HTTP status #{e.response.status}"
      rescue HTTPX::Error => e
        raise GraphQL::Client::Error, e.message
      rescue JSON::ParserError => e
        raise GraphQL::Client::Error, "Invalid JSON response: #{e.message}"
      end

      private

      def auth_headers
        return {} if Transponder.uri.user.blank? && Transponder.uri.password.blank?

        { authorization: "Basic #{Base64.strict_encode64("#{Transponder.uri.user}:#{Transponder.uri.password}")}" }
      end

      def h2c_options
        return {} if Transponder.uri.scheme == 'https' || Transponder.uri.host == 'localhost'

        { fallback_protocol: 'h2' }
      end

      def http_client = @http_client ||= CompressedHTTPClient.new(headers: auth_headers, timeout: TIMEOUT, **h2c_options)
    end

    SCHEMA_PATH = Rails.root.join('schemas/transponder.json').to_s

    HTTP = HTTPAdapter.new(endpoint)

    Schema = GraphQL::Client.load_schema(SCHEMA_PATH)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end
end
