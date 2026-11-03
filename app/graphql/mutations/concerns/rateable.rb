module Mutations
  module Concerns
    module Rateable
      extend ActiveSupport::Concern

      private

      def broker_carrier_rates(shipment, broker_carrier, declared_freight_classes)
        rates = Rate.where(broker_carrier:, declared_freight_classes:, shipment:, shipment_fingerprint: shipment.fingerprint)
        rates = rates.where(expires_at: nil).or(rates.where(expires_at: Time.current..)).to_a
        return rates if rates.any?

        Shipment::RatesService.call(broker_carrier, shipment, declared_freight_classes:, save: true)
      end

      def quotable?(rate)
        return false unless rate.cost_cents.to_i.positive?
        return true if user_type == :broker

        rate.charge.present? && rate.charge > rate.cost
      end

      def rates_for(shipment, declared_freight_classes:, broker_carrier_id: nil)
        broker_carriers = shipment.valid_broker_carriers_for_quotation(user_type)
        broker_carriers = broker_carriers.where(id: broker_carrier_id) if broker_carrier_id

        rates = broker_carriers.flat_map { |broker_carrier| broker_carrier_rates(shipment, broker_carrier, declared_freight_classes) }

        rates.select { |rate| quotable?(rate) }.sort_by(&:cost_cents)
      end

      def user_type = context[:authorizable].broker? ? :broker : :customer
    end
  end
end
