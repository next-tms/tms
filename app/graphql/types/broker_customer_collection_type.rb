module Types
  class BrokerCustomerCollectionType < Types::CollectionType
    field :items, [Types::BrokerCustomerType], null: false
  end
end
