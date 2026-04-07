module DocumentableService
  module Shipment
    class BrokerBOL < Base
      private

      def check_attributes
        @check_attributes ||= super.tap do |builder|
          builder << :bol
          builder << :bol_notes
          builder << :pickup_confirmation
          builder << :pro
          builder << :quote_id
          builder << :receiver_contact_email
          builder << :receiver_contact_name
          builder << :receiver_contact_phone
          builder << :shipper_contact_email
          builder << :shipper_contact_name
          builder << :shipper_contact_phone

          if record.picked_up?
            builder.reject! { |attribute| scheduling_attributes.include?(attribute) }
          end
        end
      end

      def pro_number_required?
        @pro_number_required ||= shipment.broker_carrier.present? &&
                                 shipment.broker_carrier.bol_requires_tracking_number?
      end

      def requirements
        @requirements ||= super.tap do |builder|
          builder << :broker_carrier
          builder << :receiver_address
          builder << :receiver_name
          builder << :shipper_address
          builder << :shipper_name
          builder << :pro if pro_number_required?
        end
      end
    end
  end
end
