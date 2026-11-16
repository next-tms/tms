module Types
  class CarrierAccountCollectionType < Types::CollectionType
    field :items, [Types::CarrierAccountType], null: false
  end
end
