# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class Base
      API_NOT_FOUND_EXCEPTIONS = [
        HyperCarrier::DocumentNotFound,
        HyperCarrier::ShipmentNotFound
      ]

      API_TIMEOUT_EXCEPTIONS = [
        EOFError,
        Errno::ECONNREFUSED,
        Net::OpenTimeout,
        Net::ReadTimeout
      ]

      SELENIUM_EXCEPTIONS = [
        Selenium::WebDriver::Error::UnknownError
      ]

      def initialize(broker_carrier:, retry_on_timeout: false, return_nil_on_404: false)
        @carrier_client = HyperCarrierApiClient.build_client(broker_carrier: broker_carrier)
        @broker_carrier = broker_carrier
        @retry_on_timeout = retry_on_timeout
        @return_nil_on_404 = return_nil_on_404
      end

      def hyper_carrier_api_call_block
        return yield unless retry_on_timeout

        result = nil
        begin
          result = yield
        rescue *API_NOT_FOUND_EXCEPTIONS
          result = nil
        rescue *API_TIMEOUT_EXCEPTIONS
          sleep(20)
          result = yield
        rescue *SELENIUM_EXCEPTIONS
          sleep(20)
          result = yield
        rescue NotImplementedError
          result = nil
        end

        result
      end

      attr_reader :carrier_client, :broker_carrier, :retry_on_timeout, :return_nil_on_404
    end
  end
end
