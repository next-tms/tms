module Types
  class RateType < Types::BaseObject
    description 'GraphQL Object for Rate Model'

    field :breakdown, [ Types::RateBreakdownType ], null: true
    field :carrier_name, String, null: true
    field :cost_cents, String, null: false
    field :cost_currency, String, null: false
    field :declared_freight_classes, Boolean, null: false
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true
    field :id, ID, null: false
    field :incomplete, Boolean, null: true
    field :reference, String, null: true
    field :transit_days, Integer, null: true

    def carrier_name
      object.broker_carrier&.carrier&.name
    end
  end
end
