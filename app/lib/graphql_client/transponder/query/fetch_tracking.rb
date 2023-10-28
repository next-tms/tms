# frozen_string_literal: true

module GraphQLClient
  class Transponder::Query::FetchTracking
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query(
          $carrier: CarrierInput!,
          $trackingNumber: String!
        ) {
          fetchTracking(
            carrier: $carrier,
            trackingNumber: $trackingNumber
          ) {
            actualPickup {
              ...GraphQLClient::Transponder::Fragment::DateTime::DETAILS
            }
            actualDelivery {
              ...GraphQLClient::Transponder::Fragment::DateTime::DETAILS
            }
            attemptedDelivery {
              ...GraphQLClient::Transponder::Fragment::DateTime::DETAILS
            }
            estimatedDelivery {
              ...GraphQLClient::Transponder::Fragment::DateTime::DETAILS
            }
            events {
              ...GraphQLClient::Transponder::Fragment::Event::DETAILS
            }
            deliverySignature
            destination {
              ...GraphQLClient::Transponder::Fragment::Location::DETAILS
            }
            origin {
              ...GraphQLClient::Transponder::Fragment::Location::DETAILS
            }
            trackingNumber
            request
            response
            error
          }
        }
    GRAPHQL
  end
end
