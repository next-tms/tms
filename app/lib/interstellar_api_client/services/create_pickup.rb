# frozen_string_literal: true

module InterstellarAPIClient
  module Services
    class CreatePickup < Base
      def create(
        delivery_from:,
        delivery_to:,
        dispatcher:,
        pickup_from:,
        pickup_to:,
        scac:,
        service:,
        shipment:
      )
        interstellar_api_call_block do
          carrier_client&.create_pickup(
            delivery_from:,
            delivery_to:,
            dispatcher:,
            pickup_from:,
            pickup_to:,
            scac:,
            service:,
            shipment:
          )
        end
      end
    end
  end
end
