# frozen_string_literal: true

module Types
  class BrokerCarrierConnectionType < BaseConnection
    description 'GraphQL Connection Type for Broker Carrier Model'

    edge_type BrokerCarrierEdgeType
  end
end
