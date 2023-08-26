# frozen_string_literal: true

module GraphqlClient
  module Fragments
    class FreightKitDateTime
      DETAILS = GraphqlClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on FreightKitDateTime {
          localDateTime
          localDate
          dateTimeWithZone
          dateTimeWithZoneName
          location {
            ...GraphqlClient::Fragments::Location::DETAILS
          }
        }
      GRAPHQL
    end
  end
end
