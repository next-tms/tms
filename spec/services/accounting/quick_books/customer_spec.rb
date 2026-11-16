require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Customer do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Customer.new }

  before { allow(Quickbooks::Service::Customer).to receive(:new).and_return(service) }

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Acme') }

    before do
      allow(service).to(receive(:find_by).and_return(results))
      found
    end

    context 'with a single match' do
      let(:results) { [Quickbooks::Model::Customer.new(company_name: 'Acme').tap { it.id = '7' }] }

      it { is_expected.to(have_attributes(id: '7', company_name: 'Acme')) }
      it { expect(service).to(have_received(:find_by).with(:display_name, 'Acme')) }
    end

    context 'with multiple matches' do
      let(:results) { [Quickbooks::Model::Customer.new, Quickbooks::Model::Customer.new] }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#save' do
    let(:customer) do
      described_class.new(
        billing_address: Accounting::Address.new(city: 'Reno', region: 'NV'),
        company_name: 'Acme, LLC',
        display_name: 'Acme'
      )
    end

    before do
      allow(service).to(receive(:create) { |record| record.tap { it.id = '99' } })
      customer.save
    end

    it { expect(customer).to(be_persisted) }
    it { expect(customer.id).to(eq('99')) }
    it { expect(service).to(have_received(:create).with(an_object_having_attributes(company_name: 'Acme, LLC', display_name: 'Acme'))) }
  end
end
