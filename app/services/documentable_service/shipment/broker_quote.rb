module DocumentableService
  module Shipment
    class BrokerQuote < Base
      private

      def check_attributes
        @check_attributes ||= super.tap do |builder|
          builder << :total_charges_cents
          builder << :total_cost_cents
          builder << :value_cents
        end
      end

      def requirements
        @requirements ||= super.tap do |builder|
          builder << :total_charges_cents
        end
      end
    end
  end
end
