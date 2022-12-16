# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    multiple_fields Queries::Shipments,
                    Queries::BrokerCarriers,
                    Queries::BrokerCustomers
  end
end
