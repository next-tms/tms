# frozen_string_literal: true

module FreightKitAPIClient
  module Services
    class FetchBOL < Base
      def find(tracking_number)
        freight_kit_api_call_block do
          carrier_client&.scanned_bol(tracking_number)
        end
      end
    end
  end
end
