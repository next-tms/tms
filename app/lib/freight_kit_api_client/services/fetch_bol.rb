module FreightKitAPIClient
  module Services
    class FetchBOL < Base
      def find(tracking_number)
        freight_kit_api_call_block { carrier_client&.scanned_bol(tracking_number) }
      end
    end
  end
end
