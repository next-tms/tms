require 'rails_helper'

RSpec.describe(BrokerWare::Location) do
  subject(:location) { described_class.call(zip_code, country_code) }

  let(:country_code) { 'USA' }
  let(:verification) { instance_double(Geo::Verification, administrative_area: 'CA', locality: 'Fremont') }
  let(:zip_code) { ' 94536 ' }

  before { allow(Geo).to(receive(:verify).and_return(verification)) }

  describe '.call' do
    it { is_expected.to(eq(city: 'Fremont', country_alpha2: 'US', region_iso31662: 'US-CA', zip_code: '94536')) }

    context 'with the verification request' do
      before { location }

      it { expect(Geo).to(have_received(:verify).with(postal_code: '94536', region_code: 'US')) }
    end

    context 'with an alpha-2 country code' do
      let(:country_code) { 'us' }

      it { is_expected.to(include(country_alpha2: 'US')) }
    end

    context 'without a country code' do
      let(:country_code) { nil }

      it { is_expected.to(include(country_alpha2: 'US')) }
    end

    context 'with an unknown country' do
      let(:country_code) { 'ZZZ' }

      it { is_expected.to(be_nil) }
    end

    context 'without a zip code' do
      let(:zip_code) { '' }

      it { is_expected.to(be_nil) }
    end

    context 'when the zip code cannot be verified' do
      let(:verification) { nil }

      it { is_expected.to(be_nil) }
    end
  end
end
