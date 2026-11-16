module Types
  class CarrierType < Types::BaseObject
    description 'GraphQL Object for Carrier Model'

    field :accounts, Types::CarrierAccountCollectionType, null: false, resolver: Resolvers::CarrierAccountsResolver
    field :id, ID, null: false
    field :legal_name, String
    field :mc_number, String
    field :name, String
    field :scac, String
  end
end
