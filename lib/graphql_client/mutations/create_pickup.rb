module GraphqlClient
  module Mutations
    class CreatePickup
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        mutation(
          $scac: String!,
          $credentials: [CarrierCredentialInput!]!,
          $deliveryFrom: ISO8601DateTime,
          $deliveryTo: ISO8601DateTime,
          $pickupFrom: ISO8601DateTime,
          $pickupTo: ISO8601DateTime,
          $service: String,
          $valueCents: Float,
          $destination: LocationInput,
          $origin: LocationInput,
          $orderNumber: String,
          $poNumber: String,
          $pro: String,
          $packages: [PackageInput!]!,
          $accessorials: [String!],
          $dispatcher: ContactInput,
        ) {
          createPickup(
            scac: $scac,
            credentials: $credentials,
            deliveryFrom: $deliveryFrom,
            deliveryTo: $deliveryTo,
            pickupFrom: $pickupFrom,
            pickupTo: $pickupTo,
            service: $service,
            valueCents: $valueCents,
            destination: $destination,
            origin: $origin,
            orderNumber: $orderNumber,
            poNumber: $poNumber,
            pro: $pro,
            packages: $packages,
            accessorials: $accessorials,
            dispatcher: $dispatcher
          ) {
            pickupNumber
            response
            request
            error
            labels {
              data
            }
          }
        }
      GRAPHQL
    end
  end
end
