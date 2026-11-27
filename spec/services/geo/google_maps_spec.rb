require 'rails_helper'

RSpec.describe(Geo::GoogleMaps, :geo) do
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:places_url) { 'https://places-key@places.googleapis.com' }

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('GOOGLE_ADDRESS_VALIDATION_URL').and_return('https://validation-key@addressvalidation.googleapis.com'))
    allow(ENV).to(receive(:fetch).with('GOOGLE_PLACES_URL').and_return(places_url))
    allow(ENV).to(receive(:fetch).with('GOOGLE_TIME_ZONE_URL').and_return('https://time-zone-key@maps.googleapis.com'))
    allow(Sentry).to(receive(:capture_exception))
    allow(Sentry).to(receive(:capture_message))
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:commercial)) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('google_maps')) }
  end

  describe '.place' do
    subject(:place) { described_class.place('place/1', provider: 'google_maps') }

    let(:body) do
      { businessStatus: 'CLOSED_PERMANENTLY', displayName: { text: 'Taco Spot' }, types: ['establishment', 'meal_takeaway'] }.to_json
    end
    let(:request_headers) { { 'X-Goog-Api-Key' => 'places-key', 'X-Goog-FieldMask' => 'businessStatus,displayName,types' } }
    let(:status) { 200 }
    let(:url) { 'https://places.googleapis.com/v1/places/place%2F1' }

    before do
      stub_request(:get, url).to_return(body:, headers:, status:)
      place
    end

    it do
      is_expected.to(
        eq(Geo::Place.new(authority: :commercial, id: 'place/1', name: 'Taco Spot', permanently_closed: true, types: ['restaurant']))
      )
    end

    it { expect(a_request(:get, url).with(headers: request_headers)).to(have_been_made) }

    context 'when the business is operational' do
      let(:body) { { businessStatus: 'OPERATIONAL' }.to_json }

      it { is_expected.to(eq(Geo::Place.new(authority: :commercial, id: 'place/1', name: nil, permanently_closed: false, types: []))) }
    end

    context 'when the business status is unknown' do
      let(:body) { {}.to_json }

      it { expect(place.permanently_closed).to(be_nil) }
    end

    context 'when the place is not found' do
      let(:body) { { error: { code: 404, message: 'Not found', status: 'NOT_FOUND' } }.to_json }
      let(:status) { 404 }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(HTTPX::HTTPError))) }
    end

    context 'with a custom URL' do
      let(:places_url) { 'http://fake@localhost:4743/' }
      let(:url) { 'http://localhost:4743/v1/places/place%2F1' }

      it { expect(place.types).to(eq(['restaurant'])) }
      it { expect(a_request(:get, url).with(headers: { 'X-Goog-Api-Key' => 'fake' })).to(have_been_made) }
    end
  end

  describe '.resolves?' do
    it { expect(described_class.resolves?('google_maps')).to(be(true)) }
    it { expect(described_class.resolves?('grid')).to(be(false)) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[geocode place time_zone verification])) }
  end

  describe '.supports?' do
    it { expect(described_class.supports?(postal_code: '97701')).to(be(true)) }
  end

  describe '.time_zone' do
    subject(:time_zone) { described_class.time_zone(latitude: 44.05, longitude: -121.31, timestamp: Time.zone.at(1_700_000_000)) }

    let(:body) { { status: 'OK', timeZoneId: 'America/Los_Angeles' }.to_json }
    let(:url) { 'https://maps.googleapis.com/maps/api/timezone/json?key=time-zone-key&location=44.05,-121.31&timestamp=1700000000' }

    before do
      stub_request(:get, url).to_return(body:, headers:)
      time_zone
    end

    it { is_expected.to(eq(Geo::TimeZone.new(authority: :commercial, id: 'America/Los_Angeles'))) }

    context 'when the request is denied' do
      let(:body) { { errorMessage: 'Bad key', status: 'REQUEST_DENIED' }.to_json }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_message).with('Time Zone API: REQUEST_DENIED Bad key')) }
    end

    context 'when there are no results' do
      let(:body) { { status: 'ZERO_RESULTS' }.to_json }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).not_to(have_received(:capture_message)) }
    end
  end

  describe '.verify' do
    subject(:verify) { described_class.verify(**postal_address) }

    let(:body) do
      {
        result: {
          address: { postalAddress: { addressLines: ['1 Main St'], administrativeArea: 'OR', locality: 'Bend', postalCode: '97701-1234' } },
          geocode: { location: { latitude: 44.05, longitude: -121.31 }, placeId: 'place-1' },
          metadata: { business: false, poBox: false, residential: true },
          verdict:
        }
      }.to_json
    end
    let(:postal_address) do
      {
        address_lines: ['1 Main St'],
        administrative_area: 'OR',
        locality: 'Bend',
        postal_code: '97701',
        region_code: 'US'
      }
    end
    let(:request_body) do
      {
        address: {
          addressLines: ['1 Main St'],
          administrativeArea: 'OR',
          locality: 'Bend',
          postalCode: '97701',
          regionCode: 'US'
        }
      }
    end
    let(:status) { 200 }
    let(:url) { 'https://addressvalidation.googleapis.com/v1:validateAddress' }
    let(:verdict) { { addressComplete: true, validationGranularity: 'PREMISE' } }

    before do
      stub_request(:post, url).to_return(body:, headers:, status:)
      verify
    end

    it do
      is_expected.to(
        eq(
          Geo::Verification.new(
            address_lines: ['1 Main St'],
            administrative_area: 'OR',
            authority: :commercial,
            business: false,
            dock: nil,
            fingerprint: nil,
            geocode_authority: :commercial,
            latitude: 44.05,
            locality: 'Bend',
            longitude: -121.31,
            place_id: 'place-1',
            place_provider: 'google_maps',
            places: nil,
            po_box: false,
            postal_code: '97701-1234',
            residential: true,
            verified: true
          )
        )
      )
    end

    it { expect(a_request(:post, url).with(body: request_body, headers: { 'X-Goog-Api-Key' => 'validation-key' })).to(have_been_made) }

    context 'when the address only matches at a coarse granularity' do
      let(:body) { { result: { address: { postalAddress: { locality: 'Bend' } }, verdict: { validationGranularity: 'OTHER' } } }.to_json }

      it { expect(verify.locality).to(eq('Bend')) }
      it { expect(verify.verified).to(be(false)) }
    end

    context 'when the address is incomplete' do
      let(:verdict) { { validationGranularity: 'PREMISE' } }

      it { expect(verify.verified).to(be(false)) }
      it { expect(verify.latitude).to(eq(44.05)) }
    end

    context 'when some components are unconfirmed' do
      let(:verdict) { { addressComplete: true, hasUnconfirmedComponents: true, validationGranularity: 'ROUTE' } }

      it { expect(verify.verified).to(be(false)) }
    end

    context 'when the server returns an error' do
      let(:body) { { error: { code: 400, message: 'Invalid address', status: 'INVALID_ARGUMENT' } }.to_json }
      let(:status) { 400 }

      it { is_expected.to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(HTTPX::HTTPError))) }
    end

    context 'when the server returns invalid JSON' do
      let(:body) { 'not json' }

      it { is_expected.to(be_nil) }
    end

    context 'with only a postal code' do
      let(:postal_address) { { locality: nil, postal_code: '97701', region_code: 'US' } }
      let(:request_body) { { address: { postalCode: '97701', regionCode: 'US' } } }

      it { expect(a_request(:post, url).with(body: request_body)).to(have_been_made) }
    end
  end
end
