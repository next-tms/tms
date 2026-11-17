module DocumentableService
  module Shipment
    class BrokerEBOL < BrokerBOL
      private

      def check_attributes = @check_attributes ||= super + %i[customer_reference value_cents]
    end
  end
end
