module GraphQLClient
  class Transponder::Query::FetchRates
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query(
          $carrier: CarrierInput!,
          $shipment: ShipmentInput!
        ) {
          fetchRates(
            carrier: $carrier,
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
          }
        }
    GRAPHQL
  end
end
