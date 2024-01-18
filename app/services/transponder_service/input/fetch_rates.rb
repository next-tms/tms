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
        { shipment: }
      end

      private

      def shipment
        Shipment.call(object, declared_freight_classes:)
      end
    end
  end
end
