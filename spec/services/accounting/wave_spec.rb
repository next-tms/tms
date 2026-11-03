require 'rails_helper'

RSpec.describe(Accounting::Wave) do
  describe '.address_from' do
    let(:address) { described_class.address_from(node) }
    let(:node) do
      {
        'addressLine1' => '1 Main St',
        'addressLine2' => nil,
        'city' => 'Reno',
        'country' => { 'code' => 'US' },
        'postalCode' => '89501',
        'province' => { 'code' => 'US-NV' }
      }
    end

    it { expect(address).to(have_attributes(city: 'Reno', country: 'US', line1: '1 Main St', postal_code: '89501', region: 'NV')) }
    it { expect(described_class.address_from(nil)).to(be_nil) }
    it { expect(described_class.address_from({})).to(be_nil) }

    context 'when Wave has no province or country' do
      let(:node) { { 'city' => 'Reno', 'country' => nil, 'province' => nil } }

      it { expect(address).to(have_attributes(city: 'Reno', country: nil, region: nil)) }
    end
  end

  describe '.address_input' do
    let(:address) { Accounting::Address.new(city: 'Reno', country: 'US', line1: '1 Main St', postal_code: '89501', region: 'NV') }
    let(:input) { described_class.address_input(address) }

    it { expect(input).to(include(addressLine1: '1 Main St', city: 'Reno', postalCode: '89501')) }
    it { expect(input).to(include(countryCode: 'US', provinceCode: 'US-NV')) }
    it { expect(described_class.address_input(nil)).to(be_nil) }

    context 'when the address has no country' do
      before { address.country = nil }

      it { expect(input).not_to(include(:countryCode, :provinceCode)) }
    end
  end
end
