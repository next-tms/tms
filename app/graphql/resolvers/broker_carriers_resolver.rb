module Resolvers
  class BrokerCarriersResolver < CollectionResolver
    MODEL = BrokerCarrier

    argument :filter, Types::BrokerCarrierFilterType, required: false

    type Types::BrokerCarrierCollectionType, null: false
  end
end
