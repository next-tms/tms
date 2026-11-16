require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Vendor do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Vendor.new }

  before { allow(Quickbooks::Service::Vendor).to receive(:new).and_return(service) }

  describe '.attributes_from' do
    let(:attributes) { described_class.attributes_from(model) }
    let(:billing_address) { Quickbooks::Model::PhysicalAddress.new(city: 'Reno', country_sub_division_code: 'NV', line1: '1 Main St') }
    let(:model) { Quickbooks::Model::Vendor.new(billing_address:, company_name: 'Star Carrier', display_name: 'Star') }

    it { expect(attributes).to(include(company_name: 'Star Carrier', display_name: 'Star')) }
    it { expect(attributes[:billing_address]).to(have_attributes(city: 'Reno', line1: '1 Main St', region: 'NV')) }

    context 'when the vendor has no billing address' do
      let(:billing_address) { nil }

      it { expect(attributes[:billing_address]).to(be_nil) }
    end
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Star') }

    before do
      allow(service).to(receive(:find_by).and_return(results))
      found
    end

    context 'with a single match' do
      let(:results) { [Quickbooks::Model::Vendor.new(company_name: 'Star Carrier').tap { it.id = '9' }] }

      it { is_expected.to(have_attributes(id: '9', company_name: 'Star Carrier')) }
      it { expect(service).to(have_received(:find_by).with(:display_name, 'Star')) }
    end

    context 'with multiple matches' do
      let(:results) { [Quickbooks::Model::Vendor.new, Quickbooks::Model::Vendor.new] }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#save' do
    let(:vendor) do
      described_class.new(
        billing_address: Accounting::Address.new(city: 'Reno', region: 'NV'),
        company_name: 'Star Carrier',
        display_name: 'Star'
      )
    end

    before do
      allow(service).to(receive(:create) { |record| record.tap { it.id = '42' } })
      vendor.save
    end

    it { expect(service).to(have_received(:create).with(an_object_having_attributes(company_name: 'Star Carrier', display_name: 'Star'))) }
    it { expect(vendor).to(be_persisted) }
    it { expect(vendor.id).to(eq('42')) }
  end
end
