require 'httpx/adapters/webmock'
require 'webmock'
require 'webmock/rspec/matchers'

RSpec.configure do |config|
  config.include(WebMock::API, :webmock)
  config.include(WebMock::Matchers, :webmock)

  config.around(:each, :webmock) do |example|
    WebMock.enable!
    WebMock.disable_net_connect!
    example.run
  ensure
    WebMock.reset!
    WebMock.disable!
  end
end
