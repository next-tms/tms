require 'rails_helper'

RSpec.describe Accounting::Wave::Customer do
  let!(:integration) { create(:integration, :wave, credentials: { access_token: 'access', business_id: 'biz' }) }

  describe '.create' do
    subject(:created) { described_class.create(company_name: 'Acme', display_name: 'Acme') }

    before { stub_wave('customer_create') }

    it { is_expected.to have_attributes(id: '1', company_name: 'Acme', display_name: 'Acme') }

    it 'sends a customerCreate mutation scoped to the business' do
      created

      expect(WebMock).to(have_requested(:post, Accounting::Wave::Service::GRAPHQL_URL).with do |request|
        body = JSON.parse(request.body)
        body['query'].include?('customerCreate') && body.dig('variables', 'input').values_at('businessId', 'name') == ['biz', 'Acme']
      end)
    end
  end

  describe '.find' do
    subject(:found) { described_class.find('1') }

    before { stub_wave('customer') }

    it { is_expected.to have_attributes(id: '1', company_name: 'Acme') }
    it { expect(found.billing_address).to have_attributes(line1: '1 A St', city: 'Reno') }
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Beta') }

    before { stub_wave('customers') }

    it { is_expected.to have_attributes(id: '2') }
  end

  describe '.all' do
    subject(:customers) { described_class.all.to_a }

    before { stub_wave('customers') }

    it { expect(customers.map(&:display_name)).to eq(['Acme', 'Beta']) }
  end

  describe 'a failed mutation' do
    subject(:created) { described_class.create(company_name: 'Acme') }

    before { stub_wave('customer_create_error') }

    it { expect { created }.to raise_error(Accounting::Error, /name: is taken/) }
  end
end
