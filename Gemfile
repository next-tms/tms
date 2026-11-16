source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.1.4.1'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder', '~> 2.15.1'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
# gem 'thruster', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 1.2'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem 'bundler-audit', require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman', require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  # gem 'rubocop-rails-omakase', require: false

  gem 'dotenv-rails', '~> 3.2.0'

  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 8.1.0'
  gem 'webmock', '~> 3.34.0'

  gem 'rubocop-next', '~> 1.0.11'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  gem 'bullet', '~> 8.3.1'

  gem 'letter_opener'
  gem 'nkf'

  gem 'listen', '>= 3.0.5', '< 3.11'
  gem 'traceroute'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'

  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers', '8.0.1'
  gem 'timecop'
end

gem 'bootstrap_form', '~> 5.6.1'
gem 'dartsass-rails'

gem 'aws-sdk-s3', '~> 1.242', group: :production

gem 'devise', '~> 5.0'
gem 'devise_invitable', '~> 2.0'
gem 'devise-pwned_password', '~> 0.2'

gem 'measured', '~> 3.2.0'

gem 'sentry-rails', '~> 6.6'
gem 'sentry-ruby', '~> 6.7'

gem 'barby'
gem 'business_time'
gem 'csv'
gem 'money-rails', '~> 3.0'
gem 'postmark-rails'

gem 'quickbooks-ruby', '~> 2.0'

gem 'action_policy'
gem 'action_policy-graphql'
gem 'bcrypt', '~> 3.1' # explicitly for GraphQL
gem 'graphql', '~> 2.6'

gem 'StreetAddress',
    git: 'https://github.com/Civitium/street-address',
    ref: '25d47a0e95a2b7e29f2ad084bf1fd99e63e3589a',
    require: 'street_address'

gem 'phony_rails'
gem 'rails-i18n', '~> 8.0'

gem 'gotenberg-ruby', '~> 1.1.0'
gem 'pstore' # explicitly for gotenberg-ruby

gem 'matrix' # explicitly for prawn
gem 'prawn', '~> 2.5.0'
gem 'prawn-labels', '~> 1.2.6', require: 'prawn/labels'

gem 'rqrcode'

gem 'pagy'
gem 'ransack', '~> 6.1'

gem 'audited'
gem 'noticed', '~> 3.1.1'
gem 'pretender'

gem 'activerecord-session_store', '~> 2.3.0'
gem 'activesupport-cache-zstd_compressor'

gem 'graphql-client'

gem 'brotli', '~> 0.5'
gem 'httpx', '~> 1.9'
gem 'zstd-ruby', '~> 2.0'
