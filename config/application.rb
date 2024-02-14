# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

if ['development', 'test'].include?(ENV['RAILS_ENV'])
  Dotenv::Railtie.load
end

module Liftoff
  class Application < Rails::Application
    if Rails.env.test?
      # Use development credentials in test
      # Set credentials content and key path for test env before `config.load_defaults` for it to take effect

      config.credentials.content_path = Rails.root.join('config/credentials/development.yml.enc')
      config.credentials.key_path = Rails.root.join('config/credentials/development.key')
    end

    config.load_defaults(7.1)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: ['assets', 'tasks'])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.i18n.fallbacks = true

    config.action_mailer.default_url_options = { host: ENV.fetch('DOMAIN', 'localhost:3000') }

    # Postmark
    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = { api_token: ENV.fetch('POSTMARK_API_TOKEN') }

    # Sidekiq
    config.active_job.queue_adapter = :sidekiq

    config.action_controller.action_on_unpermitted_parameters = :raise
    config.active_record.yaml_column_permitted_classes = [
                                                           ActiveSupport::TimeWithZone,
                                                           Array,
                                                           GooglePlaces::Photo,
                                                           GooglePlaces::Spot,
                                                           Hash,
                                                           HTTPI::Response,
                                                           FreightKit::DocumentNotFoundError,
                                                           FreightKit::ExpiredCredentialsError,
                                                           FreightKit::HTTPError,
                                                           FreightKit::InvalidCredentialsError,
                                                           FreightKit::PickupResponse,
                                                           FreightKit::ResponseError,
                                                           FreightKit::ShipmentNotFoundError,
                                                           FreightKit::UnserviceableAccessorialsError,
                                                           FreightKit::UnserviceableError,
                                                           JSON::ParserError,
                                                           StandardError,
                                                           Symbol,
                                                           Timezone::Zone,
                                                         ]

    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA1
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true
  end
end
