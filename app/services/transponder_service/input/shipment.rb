module TransponderService
  module Input
    class Shipment < Base
      attr_reader :declared_freight_classes, :estimate_reference

      def initialize(object, declared_freight_classes:, estimate_reference: nil)
        @declared_freight_classes = declared_freight_classes
        @estimate_reference = estimate_reference.presence

        super
      end

      def build
        {
          accessorials:,
          declared_value:,
          destination:,
          estimate_reference:,
          order_number: object.shipper_reference,
          origin:,
          packages:,
          pickup_at:,
          po_number: object.customer_reference,
          pro_number: object.pro
        }
      end

      private

      def accessorials
        object.combined_transponder_accessorial_codes.map { |code| { code: code.upcase } }
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

      def pickup_at
        tz = object.shipper_address&.time_zone || Setting.time_zone_name!

        today = Time.current.in_time_zone(tz).beginning_of_day

        time = if object.pickup_from.present?
                 object.pickup_from.in_time_zone(tz)
               else
                 today + 14.hours
               end

        if time < Time.current
          time = time.change(day: today.day, month: today.month, year: today.year)
          time += 1.day
        end

        Input::DateTime.call(time)
      end
    end
  end
end
