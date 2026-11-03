module Types
  class BrokerCarrierCollectionType < Types::CollectionType
    field :items, [Types::BrokerCarrierType], null: false
  end
end
