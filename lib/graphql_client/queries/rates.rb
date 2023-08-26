module GraphqlClient
  module Queries
    class Rates
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        query(
          $scac: String!,
          $credentials: [CarrierCredentialInput!]!,
          $pickupAt: ISO8601DateTime,
          $valueCents: Float,
          $destination: LocationInput,
          $origin: LocationInput,
          $packages: [PackageInput!]!,
          $accessorials: [String!]
        ) {
          fetchRates(
            scac: $scac,
            credentials: $credentials,
            pickupAt: $pickupAt,
            valueCents: $valueCents,
            destination: $destination,
            origin: $origin,
            packages: $packages,
            accessorials: $accessorials,
          ) {
            rates {
              totalCents {
                value
                currency
              }
              currency
              carrierName
              estimateReference
              withExcessiveLengthFees
              transitDays
              prices {
                cents {
                  value
                  currency
                }
                description
              }
              expiresAt
            }
          }
        }
      GRAPHQL
    end
  end
end
