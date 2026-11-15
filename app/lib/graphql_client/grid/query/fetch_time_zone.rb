module GraphQLClient
  class Grid::Query::FetchTimeZone
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        query($location: LocationInput!) {
          fetchTimeZone(location: $location) {
            authority
            expiresAt
            id
          }
        }
    GRAPHQL
  end
end
