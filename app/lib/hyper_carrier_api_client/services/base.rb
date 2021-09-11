# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class Base
      HTTP_TIMEOUT_CODES = [429, 504].freeze

      def initialize(broker_carrier:, retry_on_timeout: false, return_nil_on_404: false)
        @carrier_client = HyperCarrierApiClient.build_client(broker_carrier: broker_carrier)
        @broker_carrier = broker_carrier
        @retry_on_timeout = retry_on_timeout
        @return_nil_on_404 = return_nil_on_404
      end

      def hyper_carrier_api_call_block
        return yield unless retry_on_timeout

        begin
          result = yield
        rescue HyperCarrier::Error => e
          http_status_code = e.code
          return nil if http_status_code == 404 && return_nil_on_404
          raise if HTTP_TIMEOUT_CODES.exclude?(http_status_code)

          retry_after = 20
          retry_after = e.response_headers&.dig('retry-after')&.to_i || 40 if http_status_code == 429
          # typical value is 30-40 seconds

          sleep(retry_after)

          result = yield
        end

        result
      end

      attr_reader :carrier_client, :broker_carrier, :retry_on_timeout, :return_nil_on_404
    end
  end
end
