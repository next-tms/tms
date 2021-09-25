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

        args = {
          account: broker_carrier.account,
          debug: config[:debugging],
          username: broker_carrier.username,
          password: broker_carrier.password,
          watir_args: [:chrome, url: ENV['SELENOID_URL']]
        }

        if broker_carrier.carrier.has_seperate_website_credentials?
          args[:website_username] = broker_carrier.website_username
          args[:website_password] = broker_carrier.website_password
        end

        new_carrier_client ||= carrier.new(args)
      end
    end
  end
end
