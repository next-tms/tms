require_relative 'boot'
require_relative 'concurrency'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Rails.load if ['development', 'test'].include?(ENV['RAILS_ENV'])

module Liftoff
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

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

    config.i18n.available_locales = %i[en en-AU en-CA en-GB eo es tl zh-CN zh-TW]
    config.i18n.fallbacks = true

    config.action_mailer.default_url_options = { host: ENV.fetch('DOMAIN', 'localhost:3000') }

    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA1
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true
    config.active_record.yaml_column_permitted_classes = [
      ActiveSupport::TimeWithZone,
      Array,
      Hash,
      JSON::ParserError,
      StandardError,
      Symbol
    ]
  end
end
