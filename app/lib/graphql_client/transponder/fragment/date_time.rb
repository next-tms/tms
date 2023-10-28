# frozen_string_literal: true

module GraphQLClient
  class Transponder::Fragment::DateTime
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on DateTime {
          iso8601
          localDate
          localDateTime
          location {
            ...GraphQLClient::Transponder::Fragment::Location::DETAILS
          }
          timeZone
        }
    GRAPHQL
  end
end
