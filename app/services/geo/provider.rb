module Geo
  module Provider
    API_EXCEPTIONS = [HTTPX::Error, JSON::ParserError, TypeError].freeze
    TIMEOUT = { connect_timeout: 5, request_timeout: 10 }.freeze

    def key = name.demodulize.underscore

    private

    def commit = rescued { underscore_keys(JSON.parse(yield.body.read)) }

    def rescued
      yield
    rescue *API_EXCEPTIONS => e
      raise e if Rails.env.development?

      Sentry.capture_exception(e)

      nil
    end

    def underscore_keys(value)
      case value
      when Array then value.map { underscore_keys(it) }
      when Hash then value.to_h { |key, nested| [key.to_s.underscore.to_sym, underscore_keys(nested)] }
      else value
      end
    end
  end
end
