module TransponderService
  module Input
    class CreatePickup < Base
      def initialize(object)
        raise ArgumentError, 'object must be a Pickup' unless object.is_a?(Pickup)

        super
      end

      def build
        { delivery_from:, delivery_to:, dispatcher:, pickup_from:, pickup_to:, scac:, service:, shipment: }
      end

      private

      def delivery_from
        delivery_range.delivery_from
      end

      def delivery_range
        @delivery_range ||= Input::DateTime::DeliveryRange.new(object.shipment)
      end

      def delivery_to
        delivery_range.delivery_to
      end

      def dispatcher
        Contact.call(object.dispatcher)
      end

      def pickup_from
        pickup_range.pickup_from
      end

      def pickup_range
        @pickup_range ||= Input::DateTime::PickupRange.new(object.shipment)
      end

      def pickup_to
        pickup_range.pickup_to
      end

      def scac
        return object.tracking_carrier.scac if object.broker_carrier.acts_as_broker?

        object.broker_carrier.scac
      end

      def service
        object.rate.freight_kit_service_type.presence
      end

      def shipment
        Shipment.call(object.shipment, declared_freight_classes: object.rate.declared_freight_classes)
      end
    end
  end
end
