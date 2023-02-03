module GraphqlClient
  module Fragments
    class ShipmentEvent
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        fragment on ShipmentEvent {
          typeCode
          location {
            ...GraphqlClient::Fragments::Location::DETAILS
          }
          dateTime {
            ...GraphqlClient::Fragments::InterstellarDateTime::DETAILS
          }
        }
      GRAPHQL
    end
  end
end
