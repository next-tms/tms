# frozen_string_literal: true

module InterstellarAPIClient
  module Services
    class FetchTracking < Base
      def find(tracking_number)
        interstellar_api_call_block do
          carrier_client&.find_tracking_info(tracking_number)
        end
      end
    end
  end
end
