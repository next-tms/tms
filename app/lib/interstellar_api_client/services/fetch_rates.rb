# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class FetchRates < Base
      def find(origin, destination, packages, accessorials, declared_value_cents)
        interstellar_api_call_block do
          carrier_client&.find_rates(
            origin,
            destination,
            packages,
            accessorials:,
            declared_value_cents:
          )
        end
      end
    end
  end
end
