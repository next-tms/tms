module DocumentableService
  module Shipment
    class Base < DocumentableService::Base
      alias shipment record

      private

      def check_associations
        %i[
          broker_carrier
          items
          receiver_address
          shipment_broker_accessorials
          shipper_address
          tracking_carrier
        ]
      end

      def check_attributes
        @check_attributes ||= scheduling_attributes + %i[
          broker_carrier_id
          receiver_address_id
          shipper_address_id
          shipper_bol
          shipper_reference
          tracking_carrier_id
          tracking_carrier_pickup_confirmation
          tracking_carrier_pro
        ]
      end

      def requirements
        @requirements ||= super.tap { |builder| builder << :items }
      end

      def scheduling_attributes
        %i[
          delivery_appointment_at
          delivery_appointment_on
          delivery_hours_end_at
          delivery_hours_start_at
          pickup_hours_end_at
          pickup_hours_start_at
          pickup_on
          promised_delivery_by
        ]
      end
    end
  end
end
