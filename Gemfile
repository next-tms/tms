source 'https://rubygems.org'

ruby '3.1.1'

gem 'rails', '~> 7.0.2.3'
gem 'pg', '~> 1.3.5'
gem 'puma', '~> 5.6.4'
gem 'shakapacker', '~> 6.2.0'
gem 'jbuilder', '~> 2.11'

gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'annotate', git: 'https://github.com/dabit/annotate_models', branch: 'rails-7'
  gem 'bullet', '~> 7.0.1'
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.8'
  gem 'spring', '~> 4.0.0'
  gem 'traceroute'
end

group :test do
  gem 'capybara', '>= 3.35.3'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# brody.digital base 20191230

group :development do
  gem 'rails_real_favicon'
end

gem 'responders'

source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end
gem 'bootstrap_form', '~> 5.0.0'

gem 'aws-sdk', '~> 3.1.0', group: :production
gem 'image_processing', '~> 1.12.2'

gem 'devise', '~> 4.8.0'
gem 'devise_invitable', '~> 2.0.5'
gem 'devise-pwned_password', '~> 0.1.9'

# liftoff.rocks
gem 'turbo-rails', '~> 1.0.1'

gem 'interstellar', git: 'https://github.com/next-tms/interstellar', ref: '5f72ac8a3472913e090c725f043e46804f3fc37d'
gem 'interstellar-next', git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/interstellar-next', ref: 'e69e7656f3a62240ea386c36cf6a572f768dfb15'
gem 'spacetime', git: 'https://REDACTED:x-oauth-basic@github.com/next-tms/spacetime', ref: 'b430558c2458c6d674ec1803246ff5fcccacff94'

gem 'honeybadger', '~> 4.12'

gem 'sidekiq', '~> 6.4.1'
gem 'sidekiq-scheduler', '~> 3.1.1'

gem 'jwt'
gem 'active_model_serializers', '~> 0.10.13'
gem 'simple_command'
gem 'business_time'
gem 'timezone', '~> 1.3'
gem 'money-rails', '~> 1.15.0'
gem 'httparty'
gem 'postmark-rails'
gem 'barby'

gem 'quickbooks-ruby', '~> 1.0.20'

gem 'geocoder', '~> 1.7.5'
gem 'google_places', '~> 2.0.0'
gem 'mainstreet', git: 'https://github.com/brodyhoskins/mainstreet', ref: 'b8a57d132c89f872235183fdb6f16350fc2e308d'
gem 'open_street_map', '~> 1.2.1'
gem 'StreetAddress', git: 'https://github.com/Civitium/street-address', ref: '25d47a0e95a2b7e29f2ad084bf1fd99e63e3589a', require: 'street_address'

gem 'phony_rails'
gem 'htmlentities'

gem 'combine_pdf', '~> 1.0.22'
gem 'wicked_pdf', '~> 2.1.0'
# gem 'wkhtmltopdf-heroku', '~> 2.12.6.0', groups: %i[production staging]
gem 'wkhtmltopdf-binary', '~> 0.12.6.5', groups: %i[production staging]
gem 'wkhtmltopdf-binary-edge', '~> 0.12.6.0', groups: %i[development]
gem 'sprockets-rails', '~> 3.4.2'

gem 'pagy'
gem 'ransack', '~> 3.0.1'

gem 'public_suffix'
gem 'rqrcode'

gem 'rss_creator'

# Use Redis for Action Cable
gem 'redis', '~> 4.6'
