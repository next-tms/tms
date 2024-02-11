# frozen_string_literal: true

module GraphQLClient
  class Transponder::Mutation::CreatePickup
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        mutation(
          $carrier: CarrierInput!,
          $deliveryFrom: ISO8601DateTime,
          $deliveryTo: ISO8601DateTime,
          $dispatcher: ContactInput!,
          $pickupFrom: ISO8601DateTime!,
          $pickupTo: ISO8601DateTime!,
          $scac: String!,
          $service: String,
          $shipment: ShipmentInput!
        ) {
          createPickup(
            carrier: $carrier,
            deliveryFrom: $deliveryFrom,
            deliveryTo: $deliveryTo,
            dispatcher: $dispatcher,
            pickupFrom: $pickupFrom,
            pickupTo: $pickupTo,
            scac: $scac,
            service: $service,
            shipment: $shipment
          ) {
            labels {
              contentType
              dataBase64
            }
            pickupNumber
            request
            response
          }
        }
    GRAPHQL
  end
end
