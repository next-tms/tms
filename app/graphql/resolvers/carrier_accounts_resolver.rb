module Resolvers
  class CarrierAccountsResolver < CollectionResolver
    MODEL = BrokerCarrier

    argument :filter, Types::CarrierAccountFilterType, required: false

    type Types::CarrierAccountCollectionType, null: false
  end
end
