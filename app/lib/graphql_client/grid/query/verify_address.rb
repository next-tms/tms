module GraphQLClient
  class Grid::Query::VerifyAddress
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        query($address: AddressInput!) {
          verifyAddress(address: $address) {
            addressLines
            administrativeArea
            authority {
              lowest
            }
            business
            dock
            expiresAt
            fingerprint
            locality
            location {
              authority
              latitude
              longitude
            }
            places {
              ...GraphQLClient::Grid::Fragment::Place::DETAILS
            }
            poBox
            postalCode
            residential
            verified
          }
        }
    GRAPHQL
  end
end
