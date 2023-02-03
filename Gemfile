# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.0'

gem 'rails', '~> 7.0.4'
gem 'sprockets-rails', '~> 3.4.2'

gem 'pg', '~> 1.4.5'
gem 'puma', '~> 6.0.2'

gem 'importmap-rails', '~> 1.1.5'
gem 'stimulus-rails', '~> 1.1.1'
gem 'turbo-rails', '~> 1.3.3'

gem 'jbuilder', '~> 2.11'

gem 'redis', '~> 4.7'

gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker', '~> 3.1.0'
  gem 'pry'
  gem 'rspec-rails', '~> 6.0'
  gem 'shoulda-matchers', '5.3.0'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-shopify', '~> 2.12.0', require: false
end

group :development do
  gem 'annotate', '~> 3.2.0'
  gem 'bullet', '~> 7.0.7'
  gem 'letter_opener'
  gem 'listen', '>= 3.0.5', '< 3.9'
  gem 'rails_real_favicon'
  gem 'spring', '~> 4.1.1'
  gem 'traceroute'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 3.35.3'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'responders'

source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end

gem 'bootstrap', '~> 5.2.3'
gem 'bootstrap_form', '~> 5.1.0'
gem 'sassc-rails', '~> 2.1.2'

gem 'font-awesome-sass', '~> 6.2.1'

gem 'aws-sdk-s3', '~> 1.119.0', group: :production
gem 'image_processing', '~> 1.12.2'

gem 'devise', '~> 4.8.0'
gem 'devise_invitable', '~> 2.0.7'
gem 'devise-pwned_password', '~> 0.1.9'

gem 'interstellar', git: 'https://github.com/next-tms/interstellar', ref: 'a11f245c79f7bb826b0d68aea186a809ca336531'
gem 'interstellar-next',
    git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/interstellar-next',
    ref: 'be726ce51dbc95c0fe341dae23be4353af6ede0b'
gem 'spacetime',
    git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/spacetime',
    ref: 'b430558c2458c6d674ec1803246ff5fcccacff94'

gem 'honeybadger', '~> 5.1'

gem 'sidekiq', '~> 6.5.7'
gem 'sidekiq-scheduler', '~> 5.0.1'

gem 'active_model_serializers', '~> 0.10.13'
gem 'barby'
gem 'business_time'
gem 'httparty'
gem 'jwt'
gem 'money-rails', '~> 1.15.0'
gem 'postmark-rails'
gem 'simple_command'
gem 'timezone', '~> 1.3'

gem 'quickbooks-ruby', '~> 2.0'
gem 'stripe', '~> 6.5.0'

gem 'bcrypt', '~> 3.1' # explicitly for GraphQL
gem 'graphql', '~> 2.0'
gem 'graphiql-rails', git: 'https://github.com/rmosolgo/graphiql-rails.git', branch: 'master', groups: %i[development]
gem 'action_policy-graphql'

gem 'geocoder', '~> 1.8.1'
gem 'google_places', '~> 2.0.0'
gem 'mainstreet', git: 'https://github.com/brodyhoskins/mainstreet', ref: 'b8a57d132c89f872235183fdb6f16350fc2e308d'
gem 'open_street_map', '~> 1.2.1'
gem 'StreetAddress',
    git: 'https://github.com/Civitium/street-address',
    ref: '25d47a0e95a2b7e29f2ad084bf1fd99e63e3589a',
    require: 'street_address'

gem 'htmlentities'
gem 'phony_rails'

gem 'combine_pdf', '~> 1.0.22'
gem 'gotenberg-ruby', '~> 1.0.9'
gem 'prawn', '~> 2.4.0'
gem 'prawn-labels', '~> 1.2.6', require: 'prawn/labels'
gem 'rqrcode'

gem 'pagy'
gem 'ransack', '~> 3.2.1'

gem 'audited'
gem 'noticed'
gem 'pretender'
gem 'public_suffix'
gem 'rss_creator'

# CVE-2021-32740
# TODO: Remove this once dependencies define version > 2.4.0
gem 'addressable', '~> 2.8.1'

gem 'activerecord-session_store'
gem 'graphql-client'