require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Liftoff
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.i18n.fallbacks = true

    # Postmark
    config.action_mailer.delivery_method = :postmark

    config.action_mailer.postmark_settings = { api_token: Rails.application.credentials.postmark&.api_token }

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
      Interstellar::ResponseError,
      Interstellar::ShipmentNotFoundError,
      Interstellar::UnserviceableAccessorialsError,
      Interstellar::UnserviceableError,
      JSON::ParserError,
      StandardError,
      Timezone::Zone
    ]
  end
end
