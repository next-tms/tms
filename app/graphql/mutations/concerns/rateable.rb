module Mutations
  module Concerns
    module Rateable
      extend ActiveSupport::Concern

      private

      def quotable?(rate) = Shipment::QuotableRatesService.quotable?(rate, user_type:)

      def rates_for(shipment, declared_freight_classes:, broker_carrier_id: nil)
        Shipment::QuotableRatesService.call(shipment, broker_carrier_id:, declared_freight_classes:, user_type:)
      end

      def user_type = context[:authorizable].broker? ? :broker : :customer
    end
  end
end
