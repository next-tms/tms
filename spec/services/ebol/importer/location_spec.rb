require 'rails_helper'

RSpec.describe(EBOL::Importer::Location) do
  describe '.call' do
    subject(:attributes) { described_class.call(ActionController::Parameters.new(location).permit!, address) }

    let(:address) { create(:address) }
    let(:location) { { address1: '1 Main St', city: 'Los Angeles', country: 'USA', postalCode: '90001', stateProvince: 'CA' } }

    it { is_expected.to(include(city: 'Los Angeles', country_alpha2: 'US', id: address.id, region_iso31662: 'US-CA', street: '1 Main St')) }

    context 'with a lowercase country and state' do
      let(:location) { { country: 'can', stateProvince: 'on' } }

      it { is_expected.to(include(country_alpha2: 'CA', region_iso31662: 'CA-ON')) }
    end

    context 'with an unknown country' do
      let(:location) { { country: 'XYZ' } }

      it { is_expected.not_to(include(:country_alpha2, :region_iso31662)) }
    end

    context 'without a location' do
      subject(:attributes) { described_class.call(nil, nil) }

      it { is_expected.to(eq({})) }
    end
  end
end
