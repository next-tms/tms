require 'rails_helper'

RSpec.describe(Geo::Providers) do
  let(:geo_providers) { 'google_maps' }

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('GEO_PROVIDERS').and_return(geo_providers))
  end

  describe '.all' do
    it { expect(described_class.all).to(eq([Geo::GoogleMaps, Geo::Grid, Geo::Smarty])) }
  end

  describe '.enabled' do
    subject { described_class.enabled }

    it { is_expected.to(eq([Geo::GoogleMaps])) }

    context 'when no providers are listed' do
      let(:geo_providers) { '' }

      it { is_expected.to(be_empty) }
    end

    context 'with an unknown provider' do
      let(:geo_providers) { 'unknown,google_maps' }

      it { is_expected.to(eq([Geo::GoogleMaps])) }
    end

    context 'with providers of different authority' do
      let(:certified) { class_double(Geo::GoogleMaps, authority: :certified, key: 'certified') }
      let(:commercial) { class_double(Geo::GoogleMaps, authority: :commercial, key: 'commercial') }
      let(:geo_providers) { 'commercial,google_maps,certified' }

      before { allow(described_class).to(receive(:all).and_return([Geo::GoogleMaps, certified, commercial])) }

      it { is_expected.to(eq([certified, commercial, Geo::GoogleMaps])) }
    end
  end

  describe '.find' do
    it { expect(described_class.find('google_maps')).to(eq(Geo::GoogleMaps)) }
    it { expect(described_class.find('unknown')).to(be_nil) }
  end

  describe '.keys' do
    let(:geo_providers) { ' google_maps, ,smarty ' }

    it { expect(described_class.keys).to(eq(['google_maps', 'smarty'])) }
  end
end
