module Types
  class RateBreakdownType < Types::BaseObject
    description 'GraphQL Object for presenting Rate Breakdowns'

    field :cost_cents, Integer, null: true
    field :description, String, null: true

    def cost_cents
      line = object.with_indifferent_access
      cents = line[:cents].is_a?(Hash) ? line[:cents][:value] : line[:cents]

      (cents.presence || line.dig(:cost, :fractional))&.to_i
    end

    def description = object.with_indifferent_access[:description]
  end
end
