module Types
  class BrokerCustomerConnectionType < BaseConnection
    description 'GraphQL Connection Type for Broker Customer Model'

    edge_type BrokerCustomerEdgeType
  end
end
