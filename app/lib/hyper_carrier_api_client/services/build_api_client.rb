# frozen_string_literal: true

module HyperCarrierApiClient
  module Services
    class BuildApiClient
      def self.call(broker_carrier:)
        return nil if broker_carrier.carrier&.scac.blank?

        config = { debugging: !Rails.env.production?, timeout: 60 }

        carrier = begin
                    HyperCarrier.const_get(broker_carrier.carrier.scac)
                  rescue NameError
                    nil
                  end

        return nil if carrier.blank?

        new_carrier_client ||= carrier.new(
                                 account: broker_carrier.account,
                                 debug: config[:debugging],
                                 username: broker_carrier.username,
                                 password: broker_carrier.password
                               )
      end
    end
  end
end
