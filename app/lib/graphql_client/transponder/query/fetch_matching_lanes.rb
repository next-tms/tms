module GraphQLClient
  class Transponder::Query::FetchMatchingLanes
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query($destination: LocationInput!, $id: ID!, $origin: LocationInput!) {
          fetchCarriers(ids: [$id]) {
            matchingLanes(destination: $destination, origin: $origin) {
              id
            }
          }
        }
    GRAPHQL
  end
end
