# frozen_string_literal: true

module GraphQLClient
  class Transponder::Query::FetchPro
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query(
          $carrier: CarrierInput!,
          $dispatchedOn: ISO8601Date,
          $pickedUpOn: ISO8601Date,
          $pickupNumber: String!,
        ) {
          fetchPro(
            carrier: $carrier,
            dispatchedOn: $dispatchedOn,
            pickedUpOn: $pickedUpOn,
            pickupNumber: $pickupNumber
          )
        }
    GRAPHQL
  end
end
