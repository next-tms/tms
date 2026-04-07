# frozen_string_literal: true

module FreightKitAPIClient
  module Services
    class Base
      WATIR_EXCEPTIONS = [
                           Watir::Exception::UnknownObjectException,
                           Watir::Exception::NoValueFoundException,
                           Watir::Wait::TimeoutError
                         ].freeze

      def initialize(broker_carrier:)
        @carrier_client = FreightKitAPIClient.build_client(broker_carrier:)
        @broker_carrier = broker_carrier
      end

      def freight_kit_api_call_block
        yield
      rescue *WATIR_EXCEPTIONS => e
        handle_timeout_error(e)
      rescue Net::ReadTimeout => e
        handle_timeout_error(e)
      end

      def handle_timeout_error(error)
        cache_key = "#{broker_carrier.id}_#{error.class}"
        notified_within_an_hour = Rails.cache.read(cache_key)
        return if notified_within_an_hour

        Rails.cache.write(cache_key, 'notified', expires_in: 1.hour)

        # Notify only once per hour to prevent spam notice in Honeybadger
        # Watir Errors usually occurs due to BrokerCarrier's Web Page's Downtime
        Honeybadger.notify(
          "#{error.message} -> BrokerCarrier ID=#{broker_carrier.id} | " \
          "Name=#{broker_carrier.carrier&.name} (#{broker_carrier.carrier&.scac})",
        )

        nil
      end

      attr_reader :carrier_client, :broker_carrier
    end
  end
end
