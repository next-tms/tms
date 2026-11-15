class CompressedHTTPClient
  class << self
    def delete(url, accept: ACCEPT, **) = request(:delete, url, accept, **)

    def filter_uri(uri)
      filtered = URI(uri.to_s)
      filtered.query = PARAMETER_FILTER.filter(Rack::Utils.parse_query(filtered.query)).to_query if filtered.query.present?
      filtered.to_s
    end

    def get(url, accept: ACCEPT, **) = request(:get, url, accept, **)
    def patch(url, accept: ACCEPT, **) = request(:patch, url, accept, **)
    def post(url, accept: ACCEPT, **) = request(:post, url, accept, **)
    def put(url, accept: ACCEPT, **) = request(:put, url, accept, **)

    def user_agent
      @user_agent ||= begin
        sysname = Etc.uname[:sysname]
        arch, platform, os = sysname == 'Darwin' ? ['Intel', 'Macintosh', 'Mac OS X'] : [RbConfig::CONFIG['host_cpu'], sysname, sysname]
        parts = ['next-tms/1.0']
        parts << "(#{platform}; #{arch} #{os})"
        parts << "Rails/#{Rails.version}"
        parts << "Ruby/#{RUBY_VERSION} (#{Etc.uname[:machine]})"
        parts.join(' ')
      end
    end

    private

    def client(accept, **) = new(accept, persistent: false, **)

    def request(verb, url, accept, **options)
      arguments = options.extract!(*REQUEST_ARGUMENTS.fetch(verb))
      client(accept, **options).public_send(verb, url, **arguments)
    end
  end

  ACCEPT = 'application/json, application/vnd.api+json'.freeze
  ACCEPT_ENCODING = 'zstd, br, gzip'.freeze
  MAX_RETRIES = 5
  REQUEST_ARGUMENTS = {
    delete: %i[headers],
    get: %i[headers],
    patch: %i[body headers json],
    post: %i[body headers json],
    put: %i[body headers json]
  }.freeze
  RETRYABLE_STATUSES = [429, 503].freeze
  SENSITIVE_HTTP_HEADERS = Rails
                           .application
                           .config
                           .filter_parameters
                           .map { |parameter| /#{parameter.to_s.gsub('_', '[-_]')}/i } +
                           [/auth[-_]id/i, /authorization/i, /cookie/i, /key/i]
  PARAMETER_FILTER = ActiveSupport::ParameterFilter.new(SENSITIVE_HTTP_HEADERS)

  attr_reader :headers, :session

  def initialize(accept = ACCEPT, content_type: nil, h2c: false, headers: {}, **options)
    @h2c = h2c

    @headers = normalize_headers(headers)
    @headers['Accept'] = accept
    @headers['Accept-Encoding'] = ACCEPT_ENCODING
    @headers['Content-Type'] = content_type if content_type.present?
    @headers['User-Agent'] ||= self.class.user_agent

    @options = {
      decompress_response_body: false, # TODO: Enable once HTTPX works correctly
      persistent: true, # reuse TLS connections
      resolver_class: :system # avoid traversing Kubernetes search domains
    }.merge(options)

    @session = build_session
  end

  # The :callbacks plugin marks #close private; bypass for delegation.
  def close = session.__send__(:close)

  def delete(url, headers: {}) = with_retry { inflate(session.with(headers: normalize_headers(headers)).delete(url)).raise_for_status }
  def get(url, headers: {}) = with_retry { inflate(session.with(headers: normalize_headers(headers)).get(url)).raise_for_status }

  def patch(url, body: nil, headers: {}, json: nil)
    options = {}
    options[:body] = body unless body.nil?
    options[:json] = json unless json.nil?

    with_retry { inflate(session.with(headers: normalize_headers(headers)).patch(url, **options)).raise_for_status }
  end

  def post(url, body: nil, headers: {}, json: nil)
    options = {}
    options[:body] = body unless body.nil?
    options[:json] = json unless json.nil?

    with_retry { inflate(session.with(headers: normalize_headers(headers)).post(url, **options)).raise_for_status }
  end

  def put(url, body: nil, headers: {}, json: nil)
    options = {}
    options[:body] = body unless body.nil?
    options[:json] = json unless json.nil?

    with_retry { inflate(session.with(headers: normalize_headers(headers)).put(url, **options)).raise_for_status }
  end

  private

  def build_session
    base = @h2c ? HTTPX.plugin(:h2c) : HTTPX
    base = base.plugin(:callbacks)
    base = base.plugin(:response_cache, response_cache_store:)
    base = base
           .plugin(
             :retries,
             max_retries: MAX_RETRIES,
             retry_after: method(:retry_delay),
             retry_change_requests: true, # allow POST/PATCH retries — 429/503 mean the server didn't process the request
             retry_jitter: ->(seconds) { seconds }, # disable plugin's reducing jitter; retry_delay adds its own
             retry_on: method(:retry_on_status?)
           )
    base = base.with(headers: @headers, **@options)
    base.on_response_completed { |request, response| log(request, response) }
  end

  def filter_headers(headers) = PARAMETER_FILTER.filter(headers.to_h)

  def inflate(response)
    return response unless response.is_a?(HTTPX::Response)

    content_encoding = response.headers['content-encoding']
    data = response.body.read

    decompressed = case content_encoding
                   when 'br' then Brotli.inflate(data)
                   when 'gzip' then Zlib.gunzip(data)
                   when 'zstd' then Zstd.decompress(data)
                   else
                     data
                   end

    response.body.instance_variable_set(:@buffer, StringIO.new(decompressed))
    response.body.rewind
    response
  end

  def log(request, response)
    return unless Rails.logger.debug?

    Rails.logger.debug(<<~LOG.chomp)
      #{DateTime.now}: [#{self.class}] - #{request.verb.to_s.upcase} #{self.class.filter_uri(request.uri)} → #{response.status}
      \trequest  headers : #{filter_headers(request.headers)}
      \tresponse headers : #{filter_headers(response.headers)}
    LOG
  end

  def normalize_headers(headers) = headers.transform_keys { |key| key.to_s.tr('_', '-') }

  # NOTE: RFC 7231 §7.1.3: HTTP Retry-After header is either delta-seconds or an HTTP-date.
  def parse_retry_after(value)
    return if value.blank?
    return value.to_i if value.match?(/\A\d+\z/)

    [(Time.httpdate(value) - Time.current).to_i, 0].max
  rescue ArgumentError
    nil
  end

  def reset_session!
    @session.__send__(:close) # the :callbacks plugin marks #close private
    @session = build_session
  end

  def response_cache_store
    RailsCacheStore.new(key_prefix: "compressed_http_client/#{Digest::SHA256.hexdigest(Marshal.dump(headers))}")
  end

  def retry_delay(request, response)
    from_header = response.is_a?(HTTPX::Response) ? parse_retry_after(response.headers['retry-after']) : nil
    # HTTPX's :retries plugin decrements request.retries from max_retries to 0, so attempts_made grows each retry
    attempts_made = request.options.max_retries - request.retries
    base = from_header || (attempts_made * 2)
    base + rand(0..[base / 2.0, 5].min) # add jitter to break stampedes
  end

  def retry_on_status?(response) = response.is_a?(HTTPX::Response) && RETRYABLE_STATUSES.include?(response.status)

  def with_retry
    tries = 0
    begin
      sleep(tries * 2)
      tries += 1
      yield
    rescue HTTPX::Connection::HTTP2::GoawayError
      reset_session!
      retry if tries < 3
      raise
    rescue HTTPX::ResolveTimeoutError
      retry if tries < 3
      raise
    end
  end
end
