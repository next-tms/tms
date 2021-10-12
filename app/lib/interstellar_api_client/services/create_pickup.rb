# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class CreatePickup < Base
      def create_pickup(accessorials:, broker_carrier: destination:, origin:, packages: packages, receiver_contact_name:, shipper_contact_name:)
        interstellar_api_call_block do
          carrier_client&.create_pickup(
            packages,
            options
          )
        end
      end
    end
  end
end
