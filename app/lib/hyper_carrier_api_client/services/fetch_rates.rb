# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class FetchRates < Base
      def find(origin, destination, package_set, accessorials)
        hyper_carrier_api_call_block do
          carrier_client&.find_rates(
            origin,
            destination,
            package_set.dig(:packages),
            accessorials: accessorials
          )
        end
      end
    end
  end
end
