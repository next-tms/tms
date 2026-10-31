require 'rails_helper'

RSpec.describe('Geocoder') do
  before { sign_in(create(:root_broker_user)) }

  describe 'POST /fetch_address_by_broker_customer' do
    let(:address) { create(:address, standardized_address: create(:standardized_address)) }
    let(:broker_customer) { create(:broker_customer, primary_pickup_address: address) }

    before { post('/fetch_address_by_broker_customer', params: { broker_customer_id: broker_customer.id }) }

    it { is_expected.to(have_http_status(:ok)) }

    it do
      expect(response.parsed_body).to(
        eq(
          'city' => address.city,
          'standardized_address_id' => address.standardized_address_id,
          'state' => 'California',
          'street' => address.street,
          'street2' => address.street2,
          'zip_code' => address.zip_code
        )
      )
    end
  end

  describe 'POST /fetch_details_by_zip_code' do
    let(:location) { instance_double(Geocoder::Result::Base, data: { 'address' => { 'country' => 'United States', 'state' => 'Oregon', 'town' => 'Bend' } }) }
    let(:locations) { [location] }

    before do
      allow(Geocoder).to(receive(:search).with('97701').and_return(locations))
      post('/fetch_details_by_zip_code', params: { country: 'United States of America', postal_code: '97701' })
    end

    it { expect(response.parsed_body).to(eq('city' => 'Bend', 'state' => 'Oregon')) }

    context 'when nothing matches' do
      let(:locations) { [] }

      it { expect(response.parsed_body).to(eq('error' => 'No Location Found')) }
    end
  end

  describe 'POST /validate_address' do
    let(:geocoder) { { city: 'Fremont', region_iso31662: 'US-CA', street: '4011 Lana Tier', zip_code: '94536' } }
    let(:service) { instance_double(Address::FindOrCreateViaSmartyStreetsService, call: standardized_address) }
    let(:standardized_address) { create(:standardized_address) }

    before do
      allow(Address::FindOrCreateViaSmartyStreetsService).to(receive(:new).and_return(service))
      post('/validate_address', params: { geocoder: })
    end

    it { expect(response.parsed_body).to(eq('standardized_address_id' => standardized_address.id)) }

    context 'when the address is not found' do
      let(:standardized_address) { nil }

      it { expect(response.parsed_body).to(eq('error' => 'No Address Found')) }
    end
  end
end
