require 'rails_helper'

RSpec.describe(Transponder::ORM::CarrierAddress) do
  let(:address) { Transponder::ORM::Carrier.find_by(scac: 'SAIA').headquarters }
  let(:bare) { described_class.new(id: 'bare', city: 'Austin') }

  describe '.all' do
    it { expect(described_class.pluck(:city)).to(eq(['Johns Creek', 'Dallas', 'Austin'])) }
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:id)) }
  end

  describe '#initialize' do
    it { expect(address).to(have_attributes(country_alpha2: 'US', postal_code: '30097', region_abbreviation: 'GA', street2: nil)) }
    it { expect(bare.country_alpha2).to(be_nil) }
  end

  describe '#located_in?' do
    it { expect(address.located_in?(city: 'johns creek', region_iso31662s: ['US-GA'])).to(be(true)) }
    it { expect(address.located_in?(city: 'Austin', region_iso31662s: ['US-GA'])).to(be(false)) }
    it { expect(address.located_in?(city: 'Johns Creek', region_iso31662s: ['US-TX'])).to(be(false)) }
  end

  describe '#locality' do
    it { expect(address.locality).to(eq('Johns Creek, GA 30097')) }
    it { expect(bare.locality).to(eq('Austin')) }
  end

  describe '#pretty' do
    it { expect(address.pretty(', ')).to(eq('11465 Johns Creek Pkwy, Johns Creek, GA 30097')) }
  end

  describe '#region_iso31662' do
    it { expect(address.region_iso31662).to(eq('US-GA')) }
    it { expect(bare.region_iso31662).to(be_nil) }
  end

  describe '#to_address' do
    it { expect(address.to_address).to(be_a_new(Address)) }
    it { expect(address.to_address).to(have_attributes(city: 'Johns Creek', street: '11465 Johns Creek Pkwy', zip_code: '30097')) }
    it { expect(address.to_address).to(have_attributes(country_alpha2: 'US', region_iso31662: 'US-GA')) }
  end
end
