# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class CreatePickup < Base
      def create(origin:, destination:, packages:, accessorials:, shipper_contact_name:, shipper_name:, shipper_phone:, receiver_contact_name:, receiver_name:, receiver_phone:)
        interstellar_api_call_block do
          carrier_client&.create_pickup(
            origin,
            destination,
            packages,
            accessorials: accessorials,
            receiver_contact_name: receiver_contact_name,
            receiver_name: receiver_name,
            receiver_phone: receiver_phone,
            shipper_contact_name: shipper_contact_name,
            shipper_name: shipper_name,
            shipper_phone: shipper_phone
          )
        end
      end
    end
  end
end
