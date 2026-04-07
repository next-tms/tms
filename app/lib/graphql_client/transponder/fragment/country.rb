module GraphQLClient
  class Transponder::Fragment::Country
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on Country {
          alpha2
          alpha3
          name
        }
    GRAPHQL
  end
end
