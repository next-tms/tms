# frozen_string_literal: true

module Types
  class RateType < Types::BaseObject
    field :id, ID, null: false
    field :cost_cents, String, null: false
    field :cost_currency, String, null: false
    field :reference, String, null: true
    field :carrier_name, String, null: true
    field :with_calculated_freight_classes, Boolean, null: true
    field :incomplete, Boolean, null: true
    field :transit_days, Integer, null: true
    field :breakdown, [Types::RateBreakdownType], null: true
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true

    def carrier_name
      object.broker_carrier&.carrier&.name
    end
  end
end
