module TransponderService
  class << self
    def mutate(operation, broker_carrier, object, **kwargs)
      commit(:mutation, operation, broker_carrier, object, **kwargs)
    end

    def query(operation, broker_carrier, object, **kwargs)
      commit(:query, operation, broker_carrier, object, **kwargs)
    end

    private

    def commit(method, operation, broker_carrier, object, **kwargs)
      method_class = [
                       'GraphQLClient',
                       'Transponder',
                       method.to_s.camelize,
                       operation.to_s.camelize,
                       'DETAILS'
                     ]
                     .join('::')
                     .constantize
      variables = Query.call(operation.to_s.camelize(:lower), broker_carrier, object, **kwargs)
      response = GraphQLClient::Transponder::Client.query(method_class, variables:)

      parse_response(response, operation.to_s.camelize(:lower))
    rescue *API_EXCEPTIONS => e
      raise e if Rails.env.development?

      Honeybadger.notify(e)

      nil
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

  API_EXCEPTIONS = [
                     EOFError,
                     Errno::ECONNREFUSED,
                     Errno::ECONNRESET,
                     Net::OpenTimeout,
                     Net::ReadTimeout,
                     OpenSSL::SSL::SSLError,
                     RuntimeError
                   ].freeze
end
