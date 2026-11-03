require 'rails_helper'

RSpec.describe(Accounting::QuickBooks) do
  describe '.address_from' do
    let(:address) { described_class.address_from(physical_address) }
    let(:physical_address) do
      Quickbooks::Model::PhysicalAddress.new(
        city: 'Reno',
        country: 'USA',
        country_sub_division_code: 'NV',
        line1: '1 Main St',
        line2: 'Ste 2',
        postal_code: '89501'
      )
    end

    it { expect(address).to(have_attributes(city: 'Reno', country: 'USA', region: 'NV')) }
    it { expect(address).to(have_attributes(line1: '1 Main St', line2: 'Ste 2', postal_code: '89501')) }
    it { expect(described_class.address_from(nil)).to(be_nil) }
  end

  describe '.physical_address' do
    let(:address) { Accounting::Address.new(city: 'Reno', line1: '1 Main St', line2: 'Ste 2', postal_code: '89501', region: 'NV') }

    it { expect(described_class.physical_address(address)).to(have_attributes(city: 'Reno', country_sub_division_code: 'NV')) }
    it { expect(described_class.physical_address(address)).to(have_attributes(line1: '1 Main St', line2: 'Ste 2', postal_code: '89501')) }
    it { expect(described_class.physical_address(nil)).to(be_nil) }
  end
end
