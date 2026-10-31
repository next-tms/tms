module Mutations
  class FetchRates < BaseMutation
    description 'Fetch Shipment Rates'

    argument :broker_carrier_id, ID, required: false
    argument :declared_freight_classes, Boolean, required: false
    argument :shipment_load_id, ID, required: true

    field :rates, [Types::RateType], null: true
    field :shipment, Types::ShipmentType, null: false

    def resolve(shipment_load_id:, broker_carrier_id: nil, declared_freight_classes: false)
      shipment = Shipment.find_by(load_id: shipment_load_id)

      authorize!(shipment, to: :show?, with: ShipmentPolicy)
      raise GraphQL::ExecutionError, 'No Shipment Found' unless shipment

      rates = if broker_carrier_id
                broker_carrier = BrokerCarrier.find(broker_carrier_id)

                fetch_rates(shipment, broker_carrier, declared_freight_classes)
              else
                shipment.valid_broker_carriers_for_quotation.map do |broker_carrier|
                  fetch_rates(shipment, broker_carrier, declared_freight_classes)
                end.flatten
              end

      {
        rates: rates.select { |r| r.cost_cents.present? && r.cost_cents.positive? },
        shipment:
      }
    end

    def fetch_rates(shipment, broker_carrier, declared_freight_classes)
      rates = Rate.by_shipment_and_broker_carrier(shipment, shipment.fingerprint, broker_carrier, declared_freight_classes)
      return rates if rates.any?

      Shipment::RatesService.new(broker_carrier:, shipment:, declared_freight_classes:, save_new_rates: true).call
    end
  end
end
