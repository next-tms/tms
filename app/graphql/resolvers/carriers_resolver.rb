module Resolvers
  class CarriersResolver < CollectionResolver
    MODEL = Carrier

    argument :filter, Types::CarrierFilterType, required: false

    type Types::CarrierCollectionType, null: false
  end
end
