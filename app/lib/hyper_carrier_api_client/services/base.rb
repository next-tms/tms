# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class Base
      API_INVALID_CREDENTIALS_EXCEPTIONS = [
        HyperCarrier::ExpiredCredentialsError,
        HyperCarrier::InvalidCredentialsError
      ]

      API_NOT_FOUND_EXCEPTIONS = [
        HyperCarrier::DocumentNotFound,
        HyperCarrier::ResponseError,
        HyperCarrier::ShipmentNotFound,
        NotImplementedError
      ]

      API_TIMEOUT_EXCEPTIONS = [
        EOFError,
        Errno::ECONNREFUSED,
        Net::OpenTimeout,
        Net::ReadTimeout
      ]

      SELENIUM_EXCEPTIONS = [
        Selenium::WebDriver::Error::SessionNotCreatedError,
        Selenium::WebDriver::Error::UnexpectedAlertOpenError
      ]

      SELENIUM_TIMEOUT_EXCEPTIONS = [
        Errno::ECONNREFUSED,
        Selenium::WebDriver::Error::UnknownError,
        Selenium::WebDriver::Error::WebDriverError
      ]

      def initialize(broker_carrier:, retry_on_timeout: false, return_nil_on_404: false)
        @carrier_client = HyperCarrierApiClient.build_client(broker_carrier: broker_carrier)
        @broker_carrier = broker_carrier
        @retry_on_timeout = retry_on_timeout
        @return_nil_on_404 = return_nil_on_404
      end

      def hyper_carrier_api_call_block
        yield
      rescue *API_INVALID_CREDENTIALS_EXCEPTIONS
        nil
      rescue *API_NOT_FOUND_EXCEPTIONS
        nil
      rescue *API_TIMEOUT_EXCEPTIONS
        sleep(20)
        yield
      rescue *SELENIUM_EXCEPTIONS => e
        nil
      rescue *SELENIUM_TIMEOUT_EXCEPTIONS
        sleep(20)
        yield
      end

      attr_reader :carrier_client, :broker_carrier, :retry_on_timeout, :return_nil_on_404
    end
  end
end
