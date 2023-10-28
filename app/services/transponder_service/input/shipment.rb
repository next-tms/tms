# frozen_string_literal: true

module TransponderService
  module Input
    class Shipment < Base
      attr_reader :declared_freight_classes

      def initialize(object, declared_freight_classes:)
        @declared_freight_classes = declared_freight_classes

        super
      end

      def build
        {
          accessorials:,
          declared_value:,
          destination:,
          order_number: object.shipper_reference,
          origin:,
          packages:,
          po_number: object.customer_reference,
          pro_number: object.pro
        }
      end

      private

      def accessorials
        Accessorial.combined_accessorial_freight_kit_codes(shipment: object).map do |code|
          { code: code.upcase }
        end
      end

      def declared_value
        return if object.value.blank?

        Money.call(object.value)
      end

      def destination
        Location.call(object.receiver_address, contactable: object, attribute_prefix: :receiver)
      end

      def origin
        Location.call(object.shipper_address, contactable: object, attribute_prefix: :shipper)
      end

      def packages
        object.flattened_items.map { |item| Package.call(item, declared_freight_classes:) }
      end
    end
  end
end
