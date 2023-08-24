# frozen_string_literal: true

module FreightKitAPIClient
  module Services
    class FetchRates < Base
      def find(shipment:)
        freight_kit_api_call_block do
          carrier_client&.find_rates(shipment:)
        end
      end
    end
  end
end
