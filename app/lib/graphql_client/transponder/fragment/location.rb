module GraphQLClient
  class Transponder::Fragment::Location
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on Location {
          city
          country {
            ...GraphQLClient::Transponder::Fragment::Country::DETAILS
          }
          regionAbbreviation
        }
    GRAPHQL
  end
end
