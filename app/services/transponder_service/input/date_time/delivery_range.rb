module TransponderService
  module Input
    class DateTime
      class DeliveryRange
        attr_reader :shipment

        def initialize(shipment)
          raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(::Shipment)

          @shipment = shipment
        end

        def delivery_from
          @delivery_from ||= begin
            time = shipment.delivery_from.presence
            time = nil if time&.before?(now)

            time&.iso8601
          end
        end

        def delivery_to
          @delivery_to ||= begin
            time = shipment.delivery_by.presence
            time = nil if time&.before?(now)

            time&.iso8601
          end
        end

        private

        def now
          @now ||= Time.current.in_time_zone(tz)
        end

        def tz
          @tz ||= shipment.receiver_address.time_zone.presence || Setting.time_zone_name!
        end
      end
    end
  end
end
