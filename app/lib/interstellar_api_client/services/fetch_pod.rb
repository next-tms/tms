# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class FetchPod < Base
      def find(tracking_number)
        interstellar_api_call_block do
          carrier_client&.find_pod(tracking_number)
        end
      end
    end
  end
end
