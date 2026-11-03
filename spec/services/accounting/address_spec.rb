require 'rails_helper'

RSpec.describe(Accounting::Address) do
  let(:accounting_address) do
    described_class.new(city: 'Reno', country:, line1: '1 Main St', line2: 'Ste 2', postal_code: '89501', region: 'nv')
  end
  let(:country) { 'united states of america' }

  describe '#country_alpha2' do
    it { expect(accounting_address.country_alpha2).to(eq('US')) }

    context 'when the country is an alpha3 code' do
      let(:country) { 'can' }

      it { expect(accounting_address.country_alpha2).to(eq('CA')) }
    end

    context 'when the country is unknown' do
      let(:country) { 'Atlantis' }

      it { expect(accounting_address.country_alpha2).to(be_nil) }
    end
  end

  describe '#to_address' do
    let(:address) { accounting_address.to_address('MX') }

    it { expect(address).to(be_a_new(Address)) }
    it { expect(address).to(have_attributes(city: 'Reno', street: '1 Main St', street2: 'Ste 2', zip_code: '89501')) }
    it { expect(address).to(have_attributes(country_alpha2: 'US', region_iso31662: 'US-NV')) }

    context 'when the country is blank' do
      let(:country) { nil }

      it { expect(address).to(have_attributes(country_alpha2: 'MX', region_iso31662: 'MX-NV')) }
    end

    context 'when the region is blank' do
      before { accounting_address.region = nil }

      it { expect(address.region_iso31662).to(be_nil) }
    end
  end
end
