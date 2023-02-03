module GraphqlClient
  module Fragments
    class Location
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        fragment on InterstellarLocation {
          city
          country {
            ...GraphqlClient::Fragments::Country::DETAILS
          }
        }
      GRAPHQL
    end
  end
end
