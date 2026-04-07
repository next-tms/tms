module Types
  class CustomerType < Types::BaseObject
    description 'GraphQL Object for Customer Model'

    field :id, ID, null: false
    field :name, String
  end
end
