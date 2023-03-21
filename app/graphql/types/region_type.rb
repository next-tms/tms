# frozen_string_literal: true

module Types
  class RegionType < Types::BaseObjectWithTimestamp
    description 'GraphQL Object for Region Model'

    field :abbreviation, String, null: false
    field :country, Types::CountryType, null: false
    field :id, ID, null: false
    field :name, String, null: false
  end
end
