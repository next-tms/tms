module GraphqlClient
  module Queries
    class Tracking
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        query($scac: String!, $trackingNumber: String!, $credentials: CarrierCredentialInput!) {
          trackingInfo(scac: $scac, trackingNumber: $trackingNumber, credentials: $credentials) {
            trackingNumber
            status
            statusCode
            statusDescription
            shipTime
            shipperAddress
            estimatedDeliveryDate
            actualDeliveryDate
            deliverySignature
            origin {
              ...GraphqlClient::Fragments::Location::DETAILS
            }
            destination {
              ...GraphqlClient::Fragments::Location::DETAILS
            }
            shipmentEvents {
              ...GraphqlClient::Fragments::ShipmentEvent::DETAILS
            }
          }
        }
      GRAPHQL
    end
  end
end
