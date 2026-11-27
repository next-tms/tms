require 'httpx/adapters/webmock'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure { |config| config.before { stub_request(:get, %r{\Ahttps://api\.pwnedpasswords\.com/range/}).to_return(body: '') } }
