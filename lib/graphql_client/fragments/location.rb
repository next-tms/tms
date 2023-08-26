# frozen_string_literal: true

module GraphqlClient
  module Fragments
    class Location
      DETAILS = GraphqlClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on FreightKitLocation {
          city
          country {
            ...GraphqlClient::Fragments::Country::DETAILS
          }
          province
        }
      GRAPHQL
    end
  end
end
