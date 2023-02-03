module GraphqlClient
  module Fragments
    class InterstellarDateTime
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        fragment on InterstellarDateTime {
          localDateTime
          localDate
          dateTimeWithZone
          location {
            ...GraphqlClient::Fragments::Location::DETAILS
          }
        }
      GRAPHQL
    end
  end
end
