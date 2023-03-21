# frozen_string_literal: true

module Types
  class BrokerCustomerEdgeType < BaseEdge
    description 'GraphQL Edge Type for Broker Customer Model'

    node_type BrokerCustomerType
  end
end
