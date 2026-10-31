require 'rails_helper'

RSpec.describe(GeocoderController) do
  let(:service) { instance_double(Address::FindOrCreateViaSmartyStreetsService, call: nil) }

  before { sign_in(create(:root_broker_user)) }

  describe '#address_params' do
    subject { controller.__send__(:address_params).to_h }

    let(:attributes) { { city: 'Portland', zip_code: '97201' } }

    before { controller.params = { geocoder: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe 'POST #validate_address' do
    before do
      allow(Address::FindOrCreateViaSmartyStreetsService).to(receive(:new).and_return(service))

      post(
        :validate_address,
        format: :json,
        params: { geocoder: { city: 'Fremont', region_iso31662: 'US-CA', street: '4011 Lana Tier', zip_code: '94536' } }
      )
    end

    it do
      expect(Address::FindOrCreateViaSmartyStreetsService)
        .to(have_received(:new).with(city: 'Fremont', region_iso31662: 'US-CA', street: '4011 Lana Tier', zip_code: '94536'))
    end
  end
end
