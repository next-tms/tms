# frozen_string_literal: true

module Types
  class RateBreakdownType < Types::BaseObject
    field :cost_cents, String, null: true, method: :cents
    field :description, String, null: true
  end
end
