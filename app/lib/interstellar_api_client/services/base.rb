# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class Base
      API_INVALID_CREDENTIALS_EXCEPTIONS = [
        Interstellar::ExpiredCredentialsError,
        Interstellar::InvalidCredentialsError
      ].freeze

      API_NOT_FOUND_EXCEPTIONS = [
        Interstellar::DocumentNotFoundError,
        Interstellar::ResponseError,
        Interstellar::ShipmentNotFoundError,
        Interstellar::UnserviceableError
      ].freeze

      API_TIMEOUT_EXCEPTIONS = [
        EOFError,
        Errno::ECONNREFUSED,
        Net::OpenTimeout,
        Net::ReadTimeout
      ].freeze

      SELENIUM_EXCEPTIONS = [
        Selenium::WebDriver::Error::SessionNotCreatedError,
        Selenium::WebDriver::Error::UnexpectedAlertOpenError
      ].freeze

      SELENIUM_TIMEOUT_EXCEPTIONS = [
        Errno::ECONNREFUSED,
        Selenium::WebDriver::Error::UnknownError,
        Selenium::WebDriver::Error::WebDriverError
      ].freeze

      def initialize(broker_carrier:, retry_on_timeout: true, return_nil_on_error: true)
        @carrier_client = InterstellarApiClient.build_client(broker_carrier: broker_carrier)
        @broker_carrier = broker_carrier
        @retry_on_timeout = retry_on_timeout
        @return_nil_on_error = return_nil_on_error
        @tries = 0
      end

      def interstellar_api_call_block
        @tries += 1

        if @tries > 10
          @return_nil_on_error ? return : yield
        end

        begin
          yield
        rescue *API_INVALID_CREDENTIALS_EXCEPTIONS
          @return_nil_on_error ? return : yield
        rescue *API_NOT_FOUND_EXCEPTIONS
          @return_nil_on_error ? return : yield
        rescue *API_TIMEOUT_EXCEPTIONS
          sleep(10)
          retry
        rescue *SELENIUM_EXCEPTIONS
          @return_nil_on_error ? return : yield
        rescue *SELENIUM_TIMEOUT_EXCEPTIONS
          sleep(10)
          retry
        rescue Savon::SOAPFault
          @return_nil_on_error ? return : yield
        end
      end

      attr_reader :carrier_client, :broker_carrier, :retry_on_timeout, :return_nil_on_error
    end
  end
end
