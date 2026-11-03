module Types
  class CustomerType < Types::BaseObject
    description 'GraphQL Object for Customer Model'

    field :broker_customers, Types::BrokerCustomerCollectionType, null: false, resolver: Resolvers::BrokerCustomersResolver
    field :id, ID, null: false
    field :name, String
  end
end
