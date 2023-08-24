# frozen_string_literal: true

module GraphqlClient
  module Fragments
    class Country
      DETAILS = GraphqlClient::Transponder::Client.parse(<<-GRAPHQL)
        fragment on FreightKitCountry {
          name
          alpha2
          alpha3
          numeric
        }
      GRAPHQL
    end
  end
end
