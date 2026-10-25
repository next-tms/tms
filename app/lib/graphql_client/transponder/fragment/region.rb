module GraphQLClient
  class Transponder::Fragment::Region
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on Region {
          abbreviation
          iso31662
          name
        }
    GRAPHQL
  end
end
