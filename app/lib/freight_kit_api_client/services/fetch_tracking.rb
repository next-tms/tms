module FreightKitAPIClient
  module Services
    class FetchTracking < Base
      def find(tracking_number)
        freight_kit_api_call_block do
          carrier_client&.find_tracking_info(tracking_number)
        end
      end
    end
  end
end
