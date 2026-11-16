require 'rails_helper'

RSpec.describe(BrokerCustomer) do
  it_behaves_like 'accounting_syncable', resource: :customer, record: 'Accounting::QuickBooks::Customer'
  it_behaves_like 'companyable'

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('customer_id')) }
    it { expect(described_class.ransackable_attributes).not_to(include('default_upcharge_cents', 'default_upcharge_percentage')) }
  end

  describe '#eligible_broker_accessorials' do
    let(:record) { create(:broker_customer) }

    let!(:blanket_accessorial) { create(:broker_accessorial, accessorial: nil, broker_customer: nil, code: 'LFT') }
    let!(:customer_accessorial) { create(:broker_accessorial, accessorial: nil, broker_customer: record, code: 'RES') }

    before { create(:broker_accessorial, accessorial: nil, broker_customer: nil, code: 'RES') }

    it { expect(record.eligible_broker_accessorials).to(contain_exactly(blanket_accessorial, customer_accessorial)) }
  end

  describe '#to_accounting_customer' do
    subject { record.to_accounting_customer }

    let(:record) { create(:broker_customer, customer: create(:customer, legal_name: 'Acme Holdings, LLC', name: 'Acme Freight')) }

    it { is_expected.to(have_attributes(company_name: 'Acme Holdings, LLC', display_name: 'Acme Freight')) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:preferred_broker_carriers).dependent(:destroy)) }
    it { is_expected.to(have_many(:upcharge_rules).dependent(:destroy)) }
  end
end
