require 'rails_helper'

RSpec.describe('Geocoder') do
  let(:verification) do
    Geo::Verification.new(
      address_lines: ['4011 Lana Tier'],
      administrative_area: 'CA',
      authority: :commercial,
      business: false,
      dock: nil,
      fingerprint: nil,
      geocode_authority: :commercial,
      latitude: 37.55,
      locality: 'Fremont',
      longitude: -121.98,
      place_id: 'place-1',
      place_provider: 'google_maps',
      places: nil,
      po_box: false,
      postal_code: '94536',
      residential: true,
      verified: true
    )
  end

  before do
    allow(Geo).to(receive(:verify).and_return(verification))
    sign_in(create(:root_broker_user))
  end

  describe 'POST /fetch_address_by_broker_customer' do
    let(:address) { create(:address) }
    let(:broker_customer) { create(:broker_customer, primary_pickup_address: address) }

    before { post('/fetch_address_by_broker_customer', params: { broker_customer_id: broker_customer.id }) }

    it { is_expected.to(have_http_status(:ok)) }

    it do
      expect(response.parsed_body).to(
        eq(
          'city' => address.city,
          'region_iso31662' => 'US-CA',
          'street' => address.street,
          'street2' => address.street2,
          'zip_code' => address.zip_code
        )
      )
    end
  end

  describe 'POST /fetch_details_by_zip_code' do
    before { post('/fetch_details_by_zip_code', params: { country: 'US', postal_code: '94536' }) }

    it { expect(response.parsed_body).to(eq('city' => 'Fremont', 'region_iso31662' => 'US-CA')) }
    it { expect(Geo).to(have_received(:verify).with(postal_code: '94536', region_code: 'US')) }

    context 'when nothing matches' do
      let(:verification) { nil }

      it { expect(response.parsed_body).to(eq('error' => 'No Location Found')) }
    end

    context 'when the match has no locality' do
      let(:verification) { super().with(locality: nil, verified: false) }

      it { expect(response.parsed_body).to(eq('error' => 'No Location Found')) }
    end
  end

  describe 'POST /validate_address' do
    let(:geocoder) { { city: 'Fremont', country_alpha2: 'US', region_iso31662: 'US-CA', street: '4011 Lana Tier', zip_code: '94536' } }

    before { post('/validate_address', params: { geocoder: }) }

    it { expect(response.parsed_body).to(eq('place_id' => 'place-1')) }

    it do
      expect(Geo).to(
        have_received(:verify)
          .with(address_lines: ['4011 Lana Tier'], administrative_area: 'CA', locality: 'Fremont', postal_code: '94536', region_code: 'US')
      )
    end

    context 'when the address is not found' do
      let(:verification) { nil }

      it { expect(response.parsed_body).to(eq('error' => 'No Address Found')) }
    end

    context 'when the address is not verified' do
      let(:verification) { super().with(verified: false) }

      it { expect(response.parsed_body).to(eq('error' => 'No Address Found')) }
    end
  end
end
