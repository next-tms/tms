require 'rails_helper'

RSpec.describe(GeocoderController) do
  before { sign_in(create(:root_broker_user)) }

  describe '#address_params' do
    subject { controller.__send__(:address_params).to_h }

    let(:attributes) { { city: 'Portland', country_alpha2: 'US', zip_code: '97201' } }

    before { controller.params = { geocoder: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end
end
