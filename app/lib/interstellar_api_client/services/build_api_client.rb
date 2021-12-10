# frozen_string_literal: true

module InterstellarApiClient
  module Services
    class BuildApiClient
      def self.call(broker_carrier:)
        return nil if broker_carrier.carrier&.scac.blank?

        config = { debugging: !Rails.env.production?, timeout: 60 }

        carrier = begin
          Interstellar.const_get(broker_carrier.carrier.scac)
        rescue NameError
          nil
        end

        return nil if carrier.blank?

        args = {
          account: broker_carrier.account,
          debug: config[:debugging],
          username: broker_carrier.username,
          password: broker_carrier.password,
          selenoid_options: {
            download_url: "#{ENV['SELENOID_BASE_URL']}/download"
          },
          watir_args: [:chrome, { url: "#{ENV['SELENOID_BASE_URL']}/wd/hub/" }],
          test: !Rails.env.production?
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
