# frozen_string_literal: true

module QuickbooksApiClient
  class Base
    HTTP_TIMEOUT_CODES = [429, 504].freeze

    attr_accessor :service
    attr_reader :broker, :retry_on_timeout, :return_nil_on_404

    def initialize(broker:, retry_on_timeout: false, return_nil_on_404: true)
      @broker = broker
      @retry_on_timeout = retry_on_timeout
      @return_nil_on_404 = return_nil_on_404
      @service = nil
    end
  end
end
