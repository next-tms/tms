module Types
  class BillCollectionType < Types::CollectionType
    field :items, [Types::BillType], null: false
  end
end
