# frozen_string_literal: true

module GraphQLClient
  class Transponder::Query::FetchRates
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query(
          $carrier: CarrierInput!,
          $pickupAt: ISO8601DateTime,
          $shipment: ShipmentInput!
        ) {
          fetchRates(
            carrier: $carrier,
            pickupAt: $pickupAt,
            shipment: $shipment
          ) {
            rates {
              costs {
                blame
                cost {
                  currency
                  fractional
                }
                description
              }
              estimateReference
              expiresAt
              serviceName
              shippingCarrier {
                name
                scac
              }
              totalCost {
                currency
                fractional
              }
              transitDays
              withExcessiveLengthFees
            }
            response
            request
            error
          }
        }
    GRAPHQL
  end
end
