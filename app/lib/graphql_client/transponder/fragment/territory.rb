module GraphQLClient
  class Transponder::Fragment::Territory
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on Territory {
          country {
            alpha2
          }
          postalCodes
          regionAbbreviation
        }
    GRAPHQL
  end
end
