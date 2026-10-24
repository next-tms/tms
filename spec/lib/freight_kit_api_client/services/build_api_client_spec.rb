require 'rails_helper'

RSpec.describe(FreightKitAPIClient::Services::BuildAPIClient) do
  describe '.build_customer_location' do
    subject(:location) { described_class.build_customer_location }

    let(:address) { create(:address, street: '1 Main St Apt 4') }

    before do
      address.region.country.update!(alpha2_code: 'US')
      create(:setting, key: 'customer_service_email', value: 'help@acme.test')
      create(:setting, key: 'mailing_address', value: address.id.to_s)
      create(:setting, key: 'name', value: 'Acme Freight')
    end

    it { expect(location.address1).to(eq('1 Main St Ste 4')) }
    it { expect(location.city).to(eq(address.city)) }
    it { expect(location.contact.company_name).to(eq('Acme Freight')) }
    it { expect(location.contact.email).to(eq('robot@acme.test')) }
  end
end
