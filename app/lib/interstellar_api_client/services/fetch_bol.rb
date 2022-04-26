# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class FetchBol < Base
      def find(tracking_number)
        interstellar_api_call_block do
          carrier_client&.scanned_bol(tracking_number)
        end
      end
    end
  end
end
