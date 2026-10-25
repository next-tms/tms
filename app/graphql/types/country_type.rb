module Types
  class CountryType < Types::BaseObject
    description 'GraphQL Object for presenting Country Object'

    field :id, ID, null: false

    field :alpha2_code, Types::Iso31661Alpha2Type, null: false, method: :alpha2
    field :alpha3_code, Types::Iso31661Alpha3Type, null: true, method: :alpha3
    field :name, String, null: false
    field :un_code, Integer, null: true, method: :numeric
  end
end
