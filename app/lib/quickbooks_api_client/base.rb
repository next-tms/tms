# frozen_string_literal: true

module QuickbooksApiClient
  class Base
    BACKOFF_EXCEPTIONS = [Quickbooks::TooManyRequests].freeze
    HTTP_TIMEOUT_CODES = [429, 504].freeze
    RETRY_MAX_WAIT_SECONDS = 30

    attr_accessor :service
    attr_reader :broker, :retry_on_timeout, :return_nil_on_404

    def initialize(broker:, retry_on_timeout: false, return_nil_on_404: true)
      @broker = broker
      @retry_on_timeout = retry_on_timeout
      @return_nil_on_404 = return_nil_on_404
      @service = nil
    end

    def execute_service_call(return_nil_on_404: false)
      tries = 0

      begin
        yield
      rescue Quickbooks::IntuitRequestException => e
        return nil if e.message == 'InternalServerError' # HTTP 500
        return nil if return_nil_on_404

        raise
      rescue *QuickbooksApiClient::Base::BACKOFF_EXCEPTIONS
        raise if tries > 10

        sleep(QuickbooksApiClient::Base::RETRY_MAX_WAIT_SECONDS)
        tries += 1
        retry
      end
    end
  end
end
