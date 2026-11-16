module Resolvers
  class CustomersResolver < CollectionResolver
    MODEL = BrokerCustomer

    argument :filter, Types::CustomerFilterType, required: false

    type Types::CustomerCollectionType, null: false
  end
end
