module WaveGraphQL
  def stub_wave(fixture, query: nil)
    stub = stub_request(:post, Accounting::Wave::Service::GRAPHQL_URL)
    stub = stub.with { |request| JSON.parse(request.body)['query'].include?(query) } if query
    stub.to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: file_fixture("wave/#{fixture}.json").read)
  end
end

RSpec.configure { |config| config.include(WaveGraphQL, file_path: %r{spec/services/accounting/wave}) }
