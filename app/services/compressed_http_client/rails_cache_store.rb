class CompressedHTTPClient
  # Back HTTPX's :response_cache plugin with Rails.cache instead of relying on per-process memory.
  class RailsCacheStore
    attr_reader :key_prefix

    def initialize(key_prefix:)
      @key_prefix = key_prefix
    end

    def clear = Rails.cache.delete_matched("#{key_prefix}/*")

    def get(request)
      payload = Rails.cache.read(cache_key(request))
      return if payload.blank?

      rebuild(request, payload)
    end

    def set(request, response) = Rails.cache.write(cache_key(request), serialize(request, response))

    private

    def cache_key(request) = "#{key_prefix}/#{request.response_cache_key}"

    def rebuild(request, payload)
      original_request = request.options.request_class.new(payload[:request][:verb], payload[:request][:uri], request.options)
      original_request.merge_headers(payload[:request][:headers])

      response = request
                 .options
                 .response_class
                 .new(
                   request,
                   payload[:response][:status],
                   payload[:response][:version],
                   payload[:response][:headers]
                 )

      response.original_request = original_request
      response.finish!
      response.mark_as_cached!
      response.body.write(payload[:response][:body]) if payload[:response][:body].present?
      response.body.rewind

      response
    end

    def filter_headers(headers) = CompressedHTTPClient::PARAMETER_FILTER.filter(headers.to_h)

    def serialize(request, response)
      response.body.rewind
      body = response.body.read
      response.body.rewind

      {
        request: { headers: filter_headers(request.headers), uri: request.uri.to_s, verb: request.verb },
        response: { body:, headers: filter_headers(response.headers), status: response.status, version: response.version }
      }
    end
  end
end
