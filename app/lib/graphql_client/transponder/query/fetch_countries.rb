module GraphQLClient
  class Transponder::Query::FetchCountries
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query {
          fetchCountries {
            ...GraphQLClient::Transponder::Fragment::Country::DETAILS
            numeric
            regions {
              ...GraphQLClient::Transponder::Fragment::Region::DETAILS
            }
          }
        }
    GRAPHQL
  end
end
