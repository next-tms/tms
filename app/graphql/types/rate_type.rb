module Types
  class RateType < Types::BaseObject
    description 'GraphQL Object for Rate Model'

    field :breakdown, [Types::RateBreakdownType], visible_to: :view_costs?
    field :carrier_name, String, null: true
    field :charge_cents, Integer, visible_to: :view_charges?
    field :charge_currency, String, visible_to: :view_charges?
    field :cost_cents, Integer, visible_to: :view_costs?
    field :cost_currency, String, visible_to: :view_costs?
    field :declared_freight_classes, Boolean, null: false
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true
    field :id, ID, null: false
    field :incomplete, Boolean, null: true
    field :reference, String, null: true
    field :scac, String, null: true
    field :transit_days, Integer, null: true

    def carrier_name = object.broker_carrier&.carrier&.name
    def charge_cents = object.charge&.cents
    def charge_currency = object.charge&.currency&.iso_code
    def scac = object.broker_carrier&.carrier&.scac
  end
end
