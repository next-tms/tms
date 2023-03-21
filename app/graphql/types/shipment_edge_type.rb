# frozen_string_literal: true

module Types
  class ShipmentEdgeType < BaseEdge
    description 'Edge Type for GraphQL Shipment Object'

    node_type ShipmentType
  end
end
