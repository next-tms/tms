module Resolvers
  class BrokerCustomersResolver < CollectionResolver
    MODEL = BrokerCustomer

    argument :filter, Types::BrokerCustomerFilterType, required: false

    type Types::BrokerCustomerCollectionType, null: false
  end
end
