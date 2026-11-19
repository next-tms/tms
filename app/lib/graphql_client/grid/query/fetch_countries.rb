module GraphQLClient
  class Grid::Query::FetchCountries
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        query {
          fetchCountries {
            ...GraphQLClient::Grid::Fragment::Country::DETAILS
            numeric
            postalCode
            postalCodeFormat
            postalCodeLabel
            regions {
              ...GraphQLClient::Grid::Fragment::Region::DETAILS
            }
          }
        }
    GRAPHQL

    NAMED = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        query($name: String!) {
          fetchCountries(name: $name) {
            alpha2
          }
        }
    GRAPHQL
  end
end
