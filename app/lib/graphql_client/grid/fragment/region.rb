module GraphQLClient
  class Grid::Fragment::Region
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        fragment on Region {
          abbreviation
          iso31662
          name
        }
    GRAPHQL
  end
end
