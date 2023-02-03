module GraphqlClient
  module Fragments
    class Country
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        fragment on InterstellarCountry {
          name
          alpha2
          alpha3
          numeric
        }
      GRAPHQL
    end
  end
end
