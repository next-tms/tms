# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class Base
      def initialize(broker_carrier:)
        @carrier_client = InterstellarApiClient.build_client(broker_carrier:)
        @broker_carrier = broker_carrier
      end

      def interstellar_api_call_block
        yield
      end

      attr_reader :carrier_client, :broker_carrier
    end
  end
end
