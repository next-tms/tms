module GraphQLClient
  class Grid::Fragment::Country
    DETAILS = GraphQLClient::Grid::Client.parse(<<-GRAPHQL)
        fragment on Country {
          alpha2
          alpha3
          name
        }
    GRAPHQL
  end
end
