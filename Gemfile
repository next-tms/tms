# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.1.2'

gem 'jbuilder', '~> 2.11'
gem 'pg', '~> 1.4.2'
gem 'puma', '~> 5.6.4'
gem 'rails', '~> 7.0.3.1'
gem 'shakapacker', '~> 6.5.0'
gem 'sprockets-rails', '~> 3.4.2'

gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker', '~> 2.22.0'
  gem 'pry'
  gem 'rspec-rails', '~> 5.1'
  gem 'shoulda-matchers', '5.1.0'
end

group :development do
  gem 'annotate', '~> 3.2.0'
  gem 'bullet', '~> 7.0.2'
  gem 'letter_opener'
  gem 'listen', '>= 3.0.5', '< 3.8'
  gem 'spring', '~> 4.0.0'
  gem 'traceroute'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 3.35.3'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development do
  gem 'rails_real_favicon'
end

gem 'responders'

source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end
gem 'bootstrap_form', '~> 5.1.0'

gem 'aws-sdk', '~> 3.1.0', group: :production
gem 'image_processing', '~> 1.12.2'

gem 'devise', '~> 4.8.0'
gem 'devise_invitable', '~> 2.0.5'
gem 'devise-pwned_password', '~> 0.1.9'

gem 'turbo-rails', '~> 1.1.1'

gem 'interstellar', git: 'https://github.com/next-tms/interstellar', ref: 'ead8256c9ca0b47edf9cd9467b1fdca5e4f79161'
gem 'interstellar-next',
    git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/interstellar-next',
    ref: 'a4d46f747cf80fd47c51e651b93e05d5b97081e8'
gem 'spacetime',
    git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/spacetime',
    ref: 'b430558c2458c6d674ec1803246ff5fcccacff94'

gem 'honeybadger', '~> 4.12'

gem 'sidekiq', '~> 6.5.3'
gem 'sidekiq-scheduler', '~> 4.0.2'

gem 'active_model_serializers', '~> 0.10.13'
gem 'barby'
gem 'business_time'
gem 'httparty'
gem 'jwt'
gem 'money-rails', '~> 1.15.0'
gem 'postmark-rails'
gem 'simple_command'
gem 'timezone', '~> 1.3'

gem 'quickbooks-ruby', '~> 1.0.21'
gem 'stripe', '~> 6.5.0'

gem 'geocoder', '~> 1.8.0'
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
gem 'prawn', '~> 2.4.0'
gem 'prawn-labels', '~> 1.2.6', require: 'prawn/labels'
gem 'rqrcode'
gem 'wicked_pdf', '~> 2.6.3'
gem 'wkhtmltopdf-binary', '~> 0.12.6.5', groups: %i[production staging]
gem 'wkhtmltopdf-binary-edge', '~> 0.12.6.0', groups: %i[development]

gem 'pagy'
gem 'ransack', '~> 3.2.1'

gem 'redis', '~> 4.7' # for Action Cable

gem 'audited'
gem 'noticed'
gem 'pretender'
gem 'public_suffix'
gem 'rss_creator'

# CVE-2021-32740
# TODO: Remove this once dependencies define version > 2.4.0
gem 'addressable', '~> 2.8.0'
