module Types
  class RateBreakdownType < Types::BaseObject
    description 'GraphQL Object for presenting Rate Breakdowns'

    field :cost_cents, Integer, null: true, method: :cents
    field :description, String, null: true
  end
end
