module GraphqlClient
  module Queries
    class FetchPro
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        query(
          $scac: String!,
          $credentials: [CarrierCredentialInput!]!,
          $pickupNumber: String!,
          $pickupOn: ISO8601Date,
          $dispatchedAt: ISO8601Date,
        ) {
          fetchPro(
            scac: $scac,
            credentials: $credentials,
            pickupNumber: $pickupNumber,
            pickupOn: $pickupOn,
            dispatchedAt: $dispatchedAt
          )
        }
      GRAPHQL
    end
  end
end
