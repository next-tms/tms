module Types
  class CarrierType < Types::BaseObject
    description 'GraphQL Object for Carrier Model'

    field :id, ID, null: false
    field :mc_number, String
    field :name, String
    field :scac, String
  end
end
