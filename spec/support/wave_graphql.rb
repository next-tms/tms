require 'webmock'
require 'webmock/rspec/matchers'

WebMock.disable!

module WaveGraphQL
  include WebMock::API
  include WebMock::Matchers

  def stub_wave(fixture, query: nil)
    stub = stub_request(:post, Accounting::Wave::Service::GRAPHQL_URL)
    stub = stub.with { |request| JSON.parse(request.body)['query'].include?(query) } if query
    stub.to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: file_fixture("wave/#{fixture}.json").read)
  end
end

RSpec.configure do |config|
  config.include(WaveGraphQL, file_path: %r{spec/services/accounting/wave})

  config.around(:each, file_path: %r{spec/services/accounting/wave}) do |example|
    WebMock.enable!
    WebMock.disable_net_connect!
    example.run
  ensure
    WebMock.reset!
    WebMock.disable!
  end
end
