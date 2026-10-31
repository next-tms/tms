module FreightKitAPIClient
  module Services
    class FetchPOD < Base
      def find(tracking_number)
        freight_kit_api_call_block { carrier_client&.pod(tracking_number) }
      end
    end
  end
end
