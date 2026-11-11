module OFREP
  class << self
    def configured? = endpoint.present?
    def endpoint = ENV.fetch('OFREP_ENDPOINT', nil)

    def evaluate(key, context: {})
      response = http.post(flag_url(key), json: { context: })
      return if flag_not_found?(response)

      body = Hash(JSON.parse(response.raise_for_status.body.to_s))
      body.fetch('value') unless body['reason'] == 'DISABLED'
    rescue HTTPX::Error, JSON::ParserError, KeyError, TypeError => e
      raise Error, e.message
    end

    private

    def flag_not_found?(response) = response.try(:status) == 404 && JSON.parse(response.body.to_s)['errorCode'] == 'FLAG_NOT_FOUND'
    def flag_url(key) = "#{endpoint.chomp('/')}/ofrep/v1/evaluate/flags/#{ERB::Util.url_encode(key)}"
    def headers = ENV.fetch('OFREP_API_KEY', nil).present? ? { authorization: "Bearer #{ENV.fetch('OFREP_API_KEY')}" } : {}
    def http = HTTPX.with(headers:, timeout: TIMEOUT)
  end

  class Error < StandardError; end

  TIMEOUT = { connect_timeout: 5, request_timeout: 10 }.freeze
end
