# frozen_string_literal: true

module Types
  class CarrierType < Types::BaseObject
    field :id, ID, null: false
    field :name, String
    field :scac, String
    field :mc_number, String
  end
end
