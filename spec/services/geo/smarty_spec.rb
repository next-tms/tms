require 'rails_helper'

RSpec.describe(Geo::Smarty, :geo) do
  let(:headers) { { 'Content-Type' => 'application/json' } }

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('SMARTY_US_STREET_URL').and_return('https://id:token@us-street.api.smarty.com'))
    allow(ENV).to(receive(:fetch).with('SMARTY_US_ZIPCODE_URL').and_return('https://id:token@us-zipcode.api.smarty.com/'))
    allow(Sentry).to(receive(:capture_exception))
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:certified)) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('smarty')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[geocode verification])) }
  end

  describe '.supports?' do
    it { expect(described_class.supports?(address_lines: ['1 Main St'], region_code: 'US')).to(be(true)) }
    it { expect(described_class.supports?(postal_code: '00901', region_code: 'PR')).to(be(true)) }
    it { expect(described_class.supports?(postal_code: 'K1A 0B1', region_code: 'CA')).to(be(false)) }
    it { expect(described_class.supports?(address_lines: [''], region_code: 'US')).to(be(false)) }
  end

  describe '.verify' do
    context 'with a street address' do
      subject(:verify) { described_class.verify(**postal_address) }

      let(:body) do
        [
          {
            analysis: { dpv_match_code: },
            components: { city_name: 'Bend', plus4_code: '1234', state_abbreviation: 'OR', zipcode: '97701' },
            delivery_line_1: '1 Main St',
            metadata: { latitude: 44.05, longitude: -121.31, rdi: 'Residential', record_type: 'S' }
          }
        ].to_json
      end
      let(:dpv_match_code) { 'Y' }
      let(:postal_address) do
        {
          address_lines: ['1 main street', 'Apt 2'],
          administrative_area: 'OR',
          locality: 'Bend',
          postal_code: '97701',
          region_code: 'US'
        }
      end
      let(:query) do
        {
          'auth-id' => 'id',
          'auth-token' => 'token',
          'candidates' => '1',
          'city' => 'Bend',
          'state' => 'OR',
          'street' => '1 main street',
          'street2' => 'Apt 2',
          'zipcode' => '97701'
        }
      end
      let(:status) { 200 }
      let(:url) { 'https://us-street.api.smarty.com/street-address' }

      before do
        stub_request(:get, url).with(query: hash_including({})).to_return(body:, headers:, status:)
        verify
      end

      it do
        is_expected.to(
          eq(
            Geo::Verification.new(
              address_lines: ['1 Main St'],
              administrative_area: 'OR',
              authority: :certified,
              business: false,
              dock: nil,
              fingerprint: nil,
              geocode_authority: :certified,
              latitude: 44.05,
              locality: 'Bend',
              longitude: -121.31,
              place_id: nil,
              place_provider: nil,
              places: nil,
              po_box: false,
              postal_code: '97701-1234',
              residential: true,
              verified: true
            )
          )
        )
      end

      it { expect(a_request(:get, url).with(query:)).to(have_been_made) }

      context 'when there is no match' do
        let(:body) { [].to_json }

        it { is_expected.to(be_nil) }
      end

      context 'when the delivery point is not confirmed' do
        let(:dpv_match_code) { 'D' }

        it { expect(verify.verified).to(be(false)) }
      end

      context 'when the RDI is unknown' do
        let(:body) { [{ delivery_line_1: '1 Main St', metadata: { record_type: 'P' } }].to_json }

        it { expect(verify).to(have_attributes(business: nil, po_box: true, residential: nil)) }
      end

      context 'when the server returns an error' do
        let(:status) { 401 }

        it { is_expected.to(be_nil) }
        it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(HTTPX::HTTPError))) }
      end

      context 'with a territory' do
        let(:postal_address) { { address_lines: ['1 Calle Luna'], region_code: 'PR' } }
        let(:query) { hash_including('state' => 'PR') }

        it { expect(a_request(:get, url).with(query:)).to(have_been_made) }
      end
    end

    context 'with only a postal code' do
      subject(:verify) { described_class.verify(postal_code: '97701', region_code: 'US') }

      let(:body) do
        [
          {
            city_states: [{ city: 'Bend', state_abbreviation: 'OR' }],
            zipcodes: [{ default_city: 'Bend', latitude: 44.05, longitude: -121.31, state_abbreviation: 'OR', zipcode: '97701' }]
          }
        ].to_json
      end
      let(:url) { 'https://us-zipcode.api.smarty.com/lookup' }

      before do
        stub_request(:get, url).with(query: hash_including({})).to_return(body:, headers:)
        verify
      end

      it { is_expected.to(have_attributes(administrative_area: 'OR', authority: :certified, locality: 'Bend', verified: false)) }
      it { expect(verify).to(have_attributes(latitude: 44.05, longitude: -121.31, postal_code: '97701')) }
      it { expect(a_request(:get, url).with(query: { 'auth-id' => 'id', 'auth-token' => 'token', zipcode: '97701' })).to(have_been_made) }

      context 'when the ZIP code is invalid' do
        let(:body) { [{ reason: 'Invalid ZIP Code.', status: 'invalid_zipcode' }].to_json }

        it { is_expected.to(be_nil) }
      end
    end
  end
end
