require 'rails_helper'

RSpec.describe Accounting::Wave::Vendor do
  let!(:integration) { create(:integration, :wave, credentials: { access_token: 'access', business_id: 'biz' }) }

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Carrier Co') }

    before { stub_wave('vendors') }

    it { is_expected.to have_attributes(id: '9', company_name: 'Carrier Co') }
    it { expect(found.billing_address).to(have_attributes(city: 'Dallas', country: 'US', line1: 'PO Box 1', region: 'TX')) }
  end

  describe '.create' do
    it { expect { described_class.create(company_name: 'Carrier Co') }.to raise_error(Accounting::UnsupportedResource) }
  end
end
