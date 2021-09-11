# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class FetchBol < Base
      def find(tracking_number)
        hyper_carrier_api_call_block do
          begin
            carrier_client.find_bol(tracking_number)
          rescue NotImplementedError
            nil
          end
        end
      end
    end
  end
end
