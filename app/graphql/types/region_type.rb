# frozen_string_literal: true

module Types
  class RegionType < Types::BaseObjectWithTimestamp
    field :id, ID, null: false
    field :country, Types::CountryType, null: false
    field :name, String, null: false
    field :abbreviation, String, null: false
  end
end
