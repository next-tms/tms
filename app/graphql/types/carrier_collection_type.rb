module Types
  class CarrierCollectionType < Types::CollectionType
    field :items, [Types::CarrierType], null: false
  end
end
