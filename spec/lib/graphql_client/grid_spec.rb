require 'rails_helper'

RSpec.describe(GraphQLClient::Grid::HTTPAdapter) do # rubocop:disable RSpec/SpecFilePathFormat
  describe '#execute' do
    subject(:execute) { described_class.new.execute(document:, operation_name: 'FetchTimeZone', variables:) }

    let(:body) { { data: {} }.to_json }
    let(:document) { GraphQL.parse('query FetchTimeZone { fetchTimeZones { id } }') }
    let(:request_body) { { operationName: 'FetchTimeZone', query: document.to_query_string, variables: }.to_json }
    let(:url) { 'http://grid.internal/graphql' }
    let(:variables) { { location: { latitude: 44.05 } } }

    before do
      allow(ENV).to(receive(:fetch).and_call_original)
      allow(ENV).to(receive(:fetch).with('GRID_URL').and_return(url))
      stub_request(:post, url).to_return(body:, headers: { 'Content-Type' => 'application/json' })
      execute
    end

    it { is_expected.to(eq('data' => {})) }

    it { expect(a_request(:post, url).with(body: request_body)).to(have_been_made) }

    context 'without variables' do
      let(:variables) { {} }

      it { expect(a_request(:post, url).with(body: hash_excluding('variables'))).to(have_been_made) }
    end
  end
end
