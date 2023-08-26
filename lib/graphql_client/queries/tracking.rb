module GraphqlClient
  module Queries
    class Tracking
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        query($scac: String!, $trackingNumber: String!, $credentials: [CarrierCredentialInput!]!) {
          trackingInfo(scac: $scac, trackingNumber: $trackingNumber, credentials: $credentials) {
            trackingNumber
            status
            statusCode
            statusDescription
            shipTime {
              ...GraphqlClient::Fragments::FreightKitDateTime::DETAILS
            }
            shipperAddress
            estimatedDeliveryDate {
              ...GraphqlClient::Fragments::FreightKitDateTime::DETAILS
            }
            actualDeliveryDate {
              ...GraphqlClient::Fragments::FreightKitDateTime::DETAILS
            }
            attemptedDeliveryDate {
              ...GraphqlClient::Fragments::FreightKitDateTime::DETAILS
            }
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
            request
            response
            error
          }
        }
      GRAPHQL
    end
  end
end
