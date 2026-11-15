require 'rails_helper'

RSpec.describe(Geo::Grid, :geo, :webmock) do
  let(:body) { { data: { operation => result } }.to_json }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:operation) { 'verifyAddress' }
  let(:result) { nil }
  let(:status) { 200 }
  let(:url) { 'http://grid.internal/graphql' }

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('GRID_URL').and_return(url))
    allow(Sentry).to(receive(:capture_exception))
    allow(Sentry).to(receive(:capture_message))
    stub_request(:post, url).to_return(body:, headers:, status:)
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:postal_operator)) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('grid')) }
  end

  describe '.place' do
    subject(:place) { described_class.place('place-1', provider: 'google_maps') }

    let(:operation) { 'fetchPlace' }
    let(:request_body) do
      hash_including(
        'operationName' => 'GraphQLClient__Grid__Query__FetchPlace__DETAILS',
        'variables' => { 'id' => { 'provider' => 'GOOGLE', 'value' => 'place-1' } }
      )
    end
    let(:result) do
      { authority: 'COMMERCIAL', freightKitLocationTypes: ['RESTAURANT'], id: 'place-1', name: 'Fake Cafe', permanentlyClosed: false }
    end

    before { place }

    it { is_expected.to(eq(Geo::Place.new(authority: :commercial, id: 'place-1', name: 'Fake Cafe', permanently_closed: false, types: ['restaurant']))) }

    it { expect(a_request(:post, url).with(body: request_body)).to(have_been_made) }

    context 'when Grid has no answer' do
      let(:result) { nil }

      it { is_expected.to(be_nil) }
    end
  end

  describe '.resolves?' do
    it { expect(described_class.resolves?('google_maps')).to(be(true)) }
    it { expect(described_class.resolves?('smarty')).to(be(false)) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[geocode place time_zone verification])) }
  end

  describe '.supports?' do
    it { expect(described_class.supports?(postal_code: 'K1A 0B1', region_code: 'CA')).to(be(true)) }
  end

  describe '.time_zone' do
    subject(:time_zone) { described_class.time_zone(latitude: BigDecimal('44.05'), longitude: BigDecimal('-121.31')) }

    let(:operation) { 'fetchTimeZone' }
    let(:request_body) { hash_including('variables' => { 'location' => { 'latitude' => 44.05, 'longitude' => -121.31 } }) }
    let(:result) { { authority: 'OPEN_DATA', id: 'America/Los_Angeles' } }

    before { time_zone }

    it { is_expected.to(eq(Geo::TimeZone.new(authority: :open_data, id: 'America/Los_Angeles'))) }

    it { expect(a_request(:post, url).with(body: request_body)).to(have_been_made) }

    context 'when Grid returns errors' do
      let(:body) { { data: { fetchTimeZone: nil }, errors: [{ message: 'Provider failed' }] }.to_json }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_message).with('Grid: Provider failed')) }
    end

    context 'when the server returns an error' do
      let(:status) { 502 }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(HTTPX::HTTPError))) }
    end
  end

  describe '.verify' do
    subject(:verify) { described_class.verify(address_lines: ['1 Main St'], locality: 'Bend', postal_code: '', region_code: 'US') }

    let(:operation) { 'verifyAddress' }
    let(:request_body) do
      hash_including(
        'operationName' => 'GraphQLClient__Grid__Query__VerifyAddress__DETAILS',
        'variables' => { 'address' => { 'addressLines' => ['1 Main St'], 'locality' => 'Bend', 'regionCode' => 'US' } }
      )
    end
    let(:result) do
      {
        addressLines: ['1 Main St'],
        administrativeArea: 'OR',
        authority: { highest: 'POSTAL_OPERATOR', lowest: 'CERTIFIED', quality: 0.8 },
        business: false,
        dock: true,
        fingerprint: '0662d1d604558fc0dc511e3dd2894215',
        locality: 'Bend',
        location: { authority: 'OPEN_DATA', latitude: 44.05, longitude: -121.31 },
        places: [
          { authority: 'COMMERCIAL', freightKitLocationTypes: ['RESTAURANT'], id: 'place-1', name: 'Fake Cafe', permanentlyClosed: false }
        ],
        poBox: false,
        postalCode: '97701-1234',
        residential: true,
        verified: true
      }
    end

    before { verify }

    it do
      is_expected.to(
        eq(
          Geo::Verification.new(
            address_lines: ['1 Main St'],
            administrative_area: 'OR',
            authority: :certified,
            business: false,
            dock: true,
            fingerprint: '0662d1d604558fc0dc511e3dd2894215',
            geocode_authority: :open_data,
            latitude: 44.05,
            locality: 'Bend',
            longitude: -121.31,
            place_id: nil,
            place_provider: nil,
            places: [
              Geo::Place.new(authority: :commercial, id: 'place-1', name: 'Fake Cafe', permanently_closed: false, types: ['restaurant'])
            ],
            po_box: false,
            postal_code: '97701-1234',
            residential: true,
            verified: true
          )
        )
      )
    end

    it { expect(a_request(:post, url).with(body: request_body)).to(have_been_made) }

    context 'when Grid has no answer' do
      let(:result) { nil }

      it { is_expected.to(be_nil) }
    end
  end

  describe 'caching' do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }
    let(:expires_at) { 1.hour.from_now.iso8601 }
    let(:operation) { 'fetchTimeZone' }
    let(:result) { { authority: 'OPEN_DATA', expiresAt: expires_at, id: 'America/Los_Angeles' } }

    before do
      allow(Rails).to(receive(:cache).and_return(cache))
      2.times { described_class.time_zone(latitude: BigDecimal('44.05'), longitude: BigDecimal('-121.31')) }
    end

    it { expect(a_request(:post, url)).to(have_been_made.once) }

    context 'when the expiry is in the past' do
      let(:expires_at) { 1.hour.ago.iso8601 }

      it { expect(a_request(:post, url)).to(have_been_made.twice) }
    end

    context 'without an expiry' do
      let(:expires_at) { nil }

      it { expect(a_request(:post, url)).to(have_been_made.twice) }
    end
  end
end
