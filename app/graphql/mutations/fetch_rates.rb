module Mutations
  class FetchRates < BaseMutation
    include Mutations::Concerns::Rateable

    description 'Fetch Shipment Rates'

    argument :carrier_account_id, ID, as: :broker_carrier_id, required: false
    argument :declared_freight_classes, Boolean, default_value: false, replace_null_with_default: true, required: false
    argument :shipment_load_id, ID, required: true

    field :rates, [Types::RateType], null: false
    field :shipment, Types::ShipmentType, null: false

    def resolve(declared_freight_classes:, shipment_load_id:, broker_carrier_id: nil)
      shipment = Shipment.find_by(load_id: shipment_load_id)

      authorize!(shipment, to: :fetch_rates?, with: ShipmentPolicy)

      { rates: rates_for(shipment, broker_carrier_id:, declared_freight_classes:), shipment: }
    end
  end
end
