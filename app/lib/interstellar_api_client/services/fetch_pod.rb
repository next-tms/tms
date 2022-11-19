# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class FetchPOD < Base
      def find(tracking_number)
        interstellar_api_call_block do
          carrier_client&.pod(tracking_number)
        end
      end
    end
  end
end
