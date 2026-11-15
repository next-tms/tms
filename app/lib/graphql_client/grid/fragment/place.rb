module GraphQLClient
  class Grid::Fragment::Place
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        fragment on Place {
          authority
          expiresAt
          freightKitLocationTypes
          id
          name
          permanentlyClosed
        }
    GRAPHQL
  end
end
