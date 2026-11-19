require 'rails_helper'

RSpec.describe('PostalCodes') do
  let(:verification) do
    Geo::Verification.new(
      address_lines: [],
      administrative_area: 'CA',
      authority: :commercial,
      business: nil,
      dock: nil,
      fingerprint: nil,
      geocode_authority: :commercial,
      latitude: 37.55,
      locality: 'Fremont',
      longitude: -121.98,
      place_id: nil,
      place_provider: nil,
      places: nil,
      po_box: nil,
      postal_code: '94536',
      residential: nil,
      verified: false
    )
  end

  before do
    allow(Geo).to(receive(:verify).and_return(verification))
    sign_in(create(:root_broker_user))
  end

  describe 'GET /countries/:country_id/postal_codes/:id' do
    before { get('/countries/US/postal_codes/94536.json') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.parsed_body).to(eq('postal_code' => { 'city' => 'Fremont', 'id' => '94536', 'region_iso31662' => 'US-CA' })) }
    it { expect(response.headers['Cache-Control']).to(include('public', 'max-age=86400')) }
    it { expect(Geo).to(have_received(:verify).with(postal_code: '94536', region_code: 'US')) }

    context 'when the ETag matches' do
      before { get('/countries/US/postal_codes/94536.json', headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when the administrative area is not in the country' do
      let(:verification) { super().with(administrative_area: 'ON') }

      it { expect(response.parsed_body.dig('postal_code', 'region_iso31662')).to(be_nil) }
    end

    context 'when the administrative area is missing' do
      let(:verification) { super().with(administrative_area: nil) }

      it { expect(response.parsed_body.dig('postal_code', 'region_iso31662')).to(be_nil) }
    end

    context 'when nothing matches' do
      let(:verification) { nil }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when the match has no locality' do
      let(:verification) { super().with(locality: nil) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /countries/:country_id/postal_codes/:id when signed out' do
    before do
      sign_out(:user)
      get('/countries/US/postal_codes/94536.json')
    end

    it { is_expected.to(have_http_status(:unauthorized)) }
    it { expect(Geo).not_to(have_received(:verify)) }
  end

  describe 'GET /countries/:country_id/postal_codes/:id with an unknown country' do
    before { get('/countries/ZZ/postal_codes/94536.json') }

    it { is_expected.to(have_http_status(:not_found)) }
  end
end
