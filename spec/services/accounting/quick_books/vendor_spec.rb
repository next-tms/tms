require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Vendor do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Vendor.new }

  before { allow(Quickbooks::Service::Vendor).to receive(:new).and_return(service) }

  describe '#save' do
    subject(:saved) { vendor.save }

    let(:vendor) do
      described_class.new(
        billing_address: Accounting::Address.new(city: 'Reno', region: 'NV'),
        company_name: 'Star Carrier',
        display_name: 'Star Carrier',
      )
    end

    before { allow(service).to receive(:create) { |record| record.tap { it.id = '42' } } }

    it 'serializes and persists via the QuickBooks vendor service' do
      saved

      expect(service).to have_received(:create).with(an_object_having_attributes(company_name: 'Star Carrier'))
    end

    it 'assigns the returned id and marks the record persisted' do
      expect { saved }.to change(vendor, :persisted?).from(false).to(true)
      expect(vendor.id).to eq('42')
    end
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Star Carrier') }

    before { allow(service).to receive(:find_by).and_return(results) }

    context 'with a single match' do
      let(:results) { [ Quickbooks::Model::Vendor.new(company_name: 'Star Carrier').tap { it.id = '9' } ] }

      it { is_expected.to have_attributes(id: '9', company_name: 'Star Carrier') }

      it 'queries the QuickBooks company_name field' do
        found

        expect(service).to have_received(:find_by).with(:company_name, 'Star Carrier')
      end
    end

    context 'with multiple matches' do
      let(:results) { [ Quickbooks::Model::Vendor.new, Quickbooks::Model::Vendor.new ] }

      it { is_expected.to be_nil }
    end
  end
end
