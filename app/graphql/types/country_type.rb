# frozen_string_literal: true

module Types
  class CountryType < Types::BaseObjectWithTimestamp
    field :id, ID, null: false

    field :alpha2_code, Types::Iso31661Alpha2Type, null: false
    field :alpha3_code, Types::Iso31661Alpha2Type, null: false
    field :name, String, null: false
    field :un_code, Types::Iso31661Alpha2Type, null: false
  end
end
