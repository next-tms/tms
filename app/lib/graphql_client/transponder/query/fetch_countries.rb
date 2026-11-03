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

    NAMED = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query($name: String!) {
          fetchCountries(name: $name) {
            alpha2
          }
        }
    GRAPHQL
  end
end
