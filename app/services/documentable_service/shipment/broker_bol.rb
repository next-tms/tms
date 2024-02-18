# frozen_string_literal: true

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

          if record.picked_up?
            builder.reject! { |attribute| scheduling_attributes.include?(attribute) }
          end
        end
      end

      def missing_changes
        @missing_changes ||= super.tap do |builder|
          builder << :broker_carrier if record.broker_carrier.blank?
          builder << :pro if pro_number_required? && matched_changes.exclude?(:pro)
        end
      end

      def pro_number_required?
        @pro_number_required ||= shipment.broker_carrier.present? && shipment.broker_carrier.bol_requires_tracking_number?
      end
    end
  end
end
