require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

if ['development', 'test'].include? ENV['RAILS_ENV']
  Dotenv::Railtie.load
end

module Liftoff
  class Application < Rails::Application
    if Rails.env.test?
      # Use development credentials in test
      # Set credentials content and key path for test env before `config.load_defaults` for it to take effect

      config.credentials.content_path = Rails.root.join("config/credentials/development.yml.enc")
      config.credentials.key_path = Rails.root.join("config/credentials/development.key")
    end

    config.i18n.fallbacks = true

    config.action_mailer.default_url_options = { host: ENV.fetch('DOMAIN', 'localhost:3000') }

    # Postmark
    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = { api_token: ENV.fetch('POSTMARK_API_TOKEN') }

    # Sidekiq
    config.active_job.queue_adapter = :sidekiq

    config.eager_load_paths << Rails.root.join('lib')

    config.action_controller.action_on_unpermitted_parameters = :raise

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.yaml_column_permitted_classes = [
      ActiveSupport::TimeWithZone,
      Array,
      GooglePlaces::Photo,
      GooglePlaces::Spot,
      Hash,
      HTTPI::Response,
      Interstellar::DocumentNotFoundError,
      Interstellar::ExpiredCredentialsError,
      Interstellar::HTTPError,
      Interstellar::InvalidCredentialsError,
      Interstellar::PickupResponse,
      Interstellar::ResponseError,
      Interstellar::ShipmentNotFoundError,
      Interstellar::UnserviceableAccessorialsError,
      Interstellar::UnserviceableError,
      JSON::ParserError,
      StandardError,
      Symbol,
      Timezone::Zone
    ]
  end
end
