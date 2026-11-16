module GraphQLClient
  class Transponder::Query::FetchServe
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query($destination: LocationInput!, $id: ID!, $origin: LocationInput!) {
          fetchCarriers(ids: [$id]) {
            serve(destination: $destination, origin: $origin)
          }
        }
    GRAPHQL
  end
end
