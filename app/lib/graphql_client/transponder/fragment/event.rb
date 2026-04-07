module GraphQLClient
  class Transponder::Fragment::Event
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on Event {
          code
          location {
            ...GraphQLClient::Transponder::Fragment::Location::DETAILS
          }
          dateTime {
            ...GraphQLClient::Transponder::Fragment::DateTime::DETAILS
          }
        }
    GRAPHQL
  end
end
