# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class CreatePickup < Base
      def create(
        accessorials:,
        customer_reference:,
        delivery_from:,
        delivery_to:,
        destination:,
        dispatcher_email:,
        dispatcher_name:,
        dispatcher_phone:,
        origin:,
        packages:,
        pickup_from:,
        pickup_to:,
        receiver_contact_name:,
        receiver_name:,
        receiver_phone:,
        receiver_reference:,
        scac:,
        service:,
        shipper_contact_name:,
        shipper_name:,
        shipper_phone:,
        shipper_reference:
      )
        interstellar_api_call_block do
          carrier_client&.create_pickup(
            accessorials: accessorials,
            customer_reference: customer_reference,
            delivery_from: delivery_from,
            delivery_to: delivery_to,
            destination: destination,
            dispatcher_email: dispatcher_email,
            dispatcher_name: dispatcher_name,
            dispatcher_phone: dispatcher_phone,
            origin: origin,
            packages: packages,
            pickup_from: pickup_from,
            pickup_to: pickup_to,
            receiver_contact_name: receiver_contact_name,
            receiver_name: receiver_name,
            receiver_phone: receiver_phone,
            receiver_reference: receiver_reference,
            scac: scac,
            service: service,
            shipper_contact_name: shipper_contact_name,
            shipper_name: shipper_name,
            shipper_phone: shipper_phone,
            shipper_reference: shipper_reference
          )
        end
      end
    end
  end
end
