# frozen_string_literal: true

module DocumentableService
  module Shipment
    class Base < DocumentableService::Base
      alias_method :shipment, :record

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
                                                        receiver_name
                                                        shipper_bol
                                                        shipper_name
                                                        shipper_reference
                                                      ]
      end

      def requirements
        @requirements ||= super.tap do |builder|
          builder << :items
        end
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
