module Types
  class QueryType < Types::BaseObject
    description 'GraphQL Queries'

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    multiple_fields Queries::Shipments, Queries::BrokerCarriers, Queries::BrokerCustomers
  end
end
