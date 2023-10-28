# frozen_string_literal: true

module TransponderService
  module Input
    class FetchRates < Base
      attr_reader :declared_freight_classes

      def initialize(object, declared_freight_classes:)
        raise ArgumentError, 'object must be a Shipment' unless object.is_a?(::Shipment)

        @declared_freight_classes = declared_freight_classes

        super(object)
      end

      def build
        { pickup_at:, shipment: }
      end

      private

      def pickup_at
        pickup_range.pickup_from
      end

      def pickup_range
        @pickup_range ||= Input::DateTime::PickupRange.new(object)
      end

      def shipment
        Shipment.call(object, declared_freight_classes:)
      end
    end
  end
end
