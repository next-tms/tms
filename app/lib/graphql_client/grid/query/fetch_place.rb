module GraphQLClient
  class Grid::Query::FetchPlace
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        query($id: IdentifierInput!) {
          fetchPlace(id: $id) {
            ...GraphQLClient::Grid::Fragment::Place::DETAILS
          }
        }
    GRAPHQL
  end
end
