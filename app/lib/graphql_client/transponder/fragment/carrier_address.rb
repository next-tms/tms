module GraphQLClient
  class Transponder::Fragment::CarrierAddress
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on CarrierAddress {
          city
          country {
            alpha2
          }
          id
          postalCode
          regionAbbreviation
          street
          street2
        }
    GRAPHQL
  end
end
