# frozen_string_literal: true

module FreightKitAPIClient
  module Services
    class FetchPro < Base
      def find(pickup_number, date)
        freight_kit_api_call_block do
          carrier_client&.find_tracking_number_from_pickup_number(pickup_number, date)
        end
      end
    end
  end
end
