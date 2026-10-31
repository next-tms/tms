module DocumentableService
  module Shipment
    class BrokerDispatchSheet < Base
      private

      def check_associations
        @check_associations ||= super.tap { |builder| builder << :dispatcher }
      end

      def check_attributes
        @check_attributes ||= super.tap do |builder|
          builder << :dispatcher_id
          builder << :pickup_confirmation
          builder << :pro
          builder << :quote_id
          builder << :total_cost_cents
          builder << :value_cents
        end
      end

      def pro_number_required?
        @pro_number_required ||= shipment.broker_carrier.present? && shipment.broker_carrier.bol_requires_tracking_number?
      end

      def requirements
        @requirements ||= super.tap do |builder|
          builder << :broker_carrier
          builder << :pickup_hours_end_at
          builder << :pickup_hours_start_at
          builder << :pickup_on
          builder << :pro if pro_number_required?
          builder << :receiver_address
          builder << :shipper_address
          builder << :total_cost_cents
        end
      end
    end
  end
end
