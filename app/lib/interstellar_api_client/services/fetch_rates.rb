# frozen_string_literal: true

module InterstellarAPIClient
  module Services
    class FetchRates < Base
      def find(shipment:)
        interstellar_api_call_block do
          carrier_client&.find_rates(shipment:)
        end
      end
    end
  end
end
