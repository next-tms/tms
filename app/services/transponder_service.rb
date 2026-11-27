module TransponderService
  class << self
    def mutate(operation, broker_carrier, object, **)
      commit(:mutation, operation, broker_carrier, object, **)
    end

    def query(operation, broker_carrier, object, **)
      commit(:query, operation, broker_carrier, object, **)
    end

    private

    def commit(method, operation, broker_carrier, object, **)
      return { errors: [] } unless GraphQLClient::Transponder.enabled?

      method_class = ['GraphQLClient', 'Transponder', method.to_s.camelize, operation.to_s.camelize, 'DETAILS'].join('::').constantize
      variables = Query.call(operation.to_s.camelize(:lower), broker_carrier, object, **)
      response = GraphQLClient::Transponder::Client.query(method_class, variables:)

      parse_response(response, operation.to_s.camelize(:lower))
    rescue *API_EXCEPTIONS => e
      raise e if Rails.env.development?

      Sentry.capture_exception(e)

      { errors: [{ message: e.message }] }
    end

    def parse_response(response, operation)
      data_object = response.original_hash.dig('data', operation) || {}

      errors = if response.original_hash['errors']&.any?
                 response.original_hash['errors']
               else
                 []
               end

      object = data_object.is_a?(Hash) ? data_object : { value: data_object }

      object.merge({ errors: }).deep_transform_keys { |key| key.to_s.underscore.to_sym }
    end
  end

  API_EXCEPTIONS = [GraphQL::Client::Error, RuntimeError].freeze
end
