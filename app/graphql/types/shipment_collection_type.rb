module Types
  class ShipmentCollectionType < Types::CollectionType
    field :items, [Types::ShipmentType], null: false
  end
end
