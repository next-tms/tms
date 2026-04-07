module TransponderService
  module Input
    class DateTime
      class PickupRange
        attr_reader :shipment

        def initialize(shipment)
          raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(::Shipment)

          @shipment = shipment
        end

        def pickup_from
          @pickup_from ||= (shipment.pickup_from.presence || default_pickup_from).iso8601
        end

        def pickup_to
          @pickup_from ||= (shipment.pickup_to.presence || default_pickup_to).iso8601
        end

        private

        def default_pickup_from
          @default_pickup_from ||= now.beginning_of_day + 14.hours # 2 PM
        end

        def default_pickup_to
          @default_pickup_to ||= now.beginning_of_day + 16.hours # 4 PM
        end

        def now
          @now ||= Time.current.in_time_zone(tz)
        end

        def tz
          @tz ||= shipment.shipper_address.time_zone.presence || Setting.value!(:time_zone_name)
        end
      end
    end
  end
end
