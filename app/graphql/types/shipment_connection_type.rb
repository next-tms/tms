module Types
  class ShipmentConnectionType < BaseConnection
    description 'Connection Type for GraphQL Shipment Object'

    edge_type ShipmentEdgeType
  end
end
