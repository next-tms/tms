module Resolvers
  class ShipmentsResolver < CollectionResolver
    MODEL = Shipment

    argument :filter, Types::ShipmentFilterType, required: false

    type Types::ShipmentCollectionType, null: false
  end
end
