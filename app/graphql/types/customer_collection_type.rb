module Types
  class CustomerCollectionType < Types::CollectionType
    field :items, [Types::CustomerType], null: false
  end
end
