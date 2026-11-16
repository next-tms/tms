require 'rails_helper'

RSpec.describe(BrokerCarrier) do
  subject(:broker_carrier) { build(:broker_carrier, carrier:, password: 'secret', username: 'user') }

  let(:carrier) { create(:carrier, :saia) }

  it_behaves_like 'accounting_syncable', resource: :vendor, record: 'Accounting::QuickBooks::Vendor'

  describe '.api_configured' do
    let!(:configured) { create(:broker_carrier, carrier:, password: 'secret', username: 'user') }
    let!(:custom) { create(:broker_carrier) }
    let!(:unconfigured) { create(:broker_carrier, carrier:) }

    it { expect(described_class.api_configured).to(contain_exactly(configured)) }
    it { expect(described_class.api_unconfigured).to(contain_exactly(custom, unconfigured)) }
  end

  describe '.companyable_order' do
    let!(:alpha) { create(:broker_carrier, carrier: create(:carrier, name: 'Alpha')) }
    let!(:zulu) { create(:broker_carrier, carrier: create(:carrier, name: 'Zulu')) }

    it { expect(described_class.companyable_order).to(eq([alpha, zulu])) }
  end

  describe '.encrypted_attributes' do
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_account_number)) }
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_bank_name)) }
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_routing_number)) }
  end

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(eq(['broker_customer', 'carrier'])) }
    it { expect(described_class.ransackable_associations(build(:carrier_user))).to(eq(['carrier'])) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('broker_customer_id', 'carrier_id')) }
  end

  describe '#ach?' do
    it { expect(build(:broker_carrier, encrypted_ach_account_number: '1234', encrypted_ach_routing_number: '123456789')).to(be_ach) }
    it { expect(build(:broker_carrier, encrypted_ach_account_number: '1234')).not_to(be_ach) }
    it { expect(build(:broker_carrier, encrypted_ach_routing_number: '123456789')).not_to(be_ach) }
  end

  describe '#api_configured?' do
    it { is_expected.to(be_api_configured) }

    context 'when a credential is missing' do
      before { broker_carrier.password = nil }

      it { is_expected.not_to(be_api_configured) }
    end

    context 'when the carrier needs only host credentials and an API key' do
      let(:carrier) { create(:carrier, :tql) }

      before { broker_carrier.encrypted_api_key = 'key' }

      it { is_expected.to(be_api_configured) }
    end

    context 'when the carrier is custom' do
      let(:carrier) { create(:carrier) }

      it { is_expected.not_to(be_api_configured) }
    end
  end

  describe '#bol_requires_tracking_number?' do
    it { expect(broker_carrier.bol_requires_tracking_number?).to(be(true)) }

    context 'when the account ignores it' do
      before { broker_carrier.ignore_bol_requires_tracking_number = true }

      it { expect(broker_carrier.bol_requires_tracking_number?).to(be(false)) }
    end

    context 'when the carrier is custom' do
      let(:carrier) { create(:carrier) }

      it { expect(broker_carrier.bol_requires_tracking_number?).to(be(false)) }
    end
  end

  describe '#broker_customer_specific_name' do
    let(:broker_customer) { create(:broker_customer) }

    it { expect(broker_carrier.broker_customer_specific_name).to(eq(carrier.name)) }

    context 'when the account belongs to a customer' do
      before { broker_carrier.broker_customer = broker_customer }

      it { expect(broker_carrier.name).to(eq("#{carrier.name} - #{broker_customer.customer.name}")) }
    end
  end

  describe '#credential_columns' do
    it { expect(broker_carrier.credential_columns).to(eq(%i[username password])) }

    context 'when the carrier needs an API key through a proxy' do
      let(:carrier) { create(:carrier, :tql) }

      it { expect(broker_carrier.credential_columns).to(eq(%i[encrypted_api_key])) }
    end
  end

  describe '#find_or_build_check_mailing_address' do
    it { expect(broker_carrier.find_or_build_check_mailing_address).to(have_attributes(city: 'Dallas', street: 'PO Box 730532')) }
    it { expect { broker_carrier.find_or_build_check_mailing_address }.to(change(broker_carrier, :check_mailing_address).from(nil)) }

    context 'when the account has its own address' do
      let(:check_mailing_address) { build(:address) }

      before { broker_carrier.check_mailing_address = check_mailing_address }

      it { expect(broker_carrier.find_or_build_check_mailing_address).to(eq(check_mailing_address)) }
    end

    context 'when nothing can be imported' do
      let(:carrier) { create(:carrier) }

      it { expect(broker_carrier.find_or_build_check_mailing_address).to(be_a_new(Address)) }
      it { expect(broker_carrier.find_or_build_check_mailing_address.city).to(be_nil) }
    end
  end

  describe '#imported_check_mailing_address' do
    let(:accounting_vendor) { Accounting::Vendor.new(billing_address:) }
    let(:billing_address) { Accounting::Address.new(city: 'Reno', postal_code: '89501', region: 'NV') }

    let(:vendor_class) { class_double(Accounting::Vendor, find: accounting_vendor) }

    before { create(:setting, key: 'mailing_address', value: create(:address).id.to_s) }

    it { expect(broker_carrier.imported_check_mailing_address.city).to(eq('Dallas')) }

    context 'when the accounting vendor has a billing address' do
      before do
        broker_carrier.accounting_vendor_id = 'V1'
        allow(Accounting).to(receive_messages(connected?: true, record_class: vendor_class, supports?: true))
      end

      it { expect(broker_carrier.imported_check_mailing_address).to(have_attributes(city: 'Reno', region_iso31662: 'US-NV')) }
    end

    context 'when the accounting vendor has no billing address' do
      let(:accounting_vendor) { Accounting::Vendor.new }

      before do
        broker_carrier.accounting_vendor_id = 'V1'
        allow(Accounting).to(receive_messages(connected?: true, record_class: vendor_class, supports?: true))
      end

      it { expect(broker_carrier.imported_check_mailing_address.city).to(eq('Dallas')) }
    end
  end

  describe '#payable_check_mailing_address' do
    it { expect(broker_carrier.payable_check_mailing_address.city).to(eq('Dallas')) }

    context 'when the account has its own address' do
      let(:check_mailing_address) { build(:address) }

      before { broker_carrier.check_mailing_address = check_mailing_address }

      it { expect(broker_carrier.payable_check_mailing_address).to(eq(check_mailing_address)) }
    end

    context 'when the carrier is custom' do
      let(:carrier) { create(:carrier) }

      it { expect(broker_carrier.payable_check_mailing_address).to(be_nil) }
    end
  end

  describe '#to_accounting_vendor' do
    let(:check_mailing_address) { create(:address, city: 'Fremont') }

    before { broker_carrier.check_mailing_address = check_mailing_address }

    it { expect(broker_carrier.to_accounting_vendor).to(have_attributes(company_name: carrier.name, display_name: carrier.name)) }
    it { expect(broker_carrier.to_accounting_vendor.billing_address.city).to(eq('Fremont')) }

    context 'when the account has no address' do
      let(:check_mailing_address) { nil }

      it { expect(broker_carrier.to_accounting_vendor.billing_address.city).to(eq('Dallas')) }
    end

    context 'when the carrier has a legal name' do
      before { carrier.legal_name = 'Saia, LLC' }

      it { expect(broker_carrier.to_accounting_vendor).to(have_attributes(company_name: 'Saia, LLC', display_name: carrier.name)) }
    end
  end

  describe 'normalizations' do
    it { expect(described_class.normalize_value_for(:encrypted_ach_account_number, ' 12 34 ')).to(eq('12 34')) }
    it { expect(described_class.normalize_value_for(:encrypted_ach_bank_name, " First \n Bank ")).to(eq('First Bank')) }
    it { expect(described_class.normalize_value_for(:encrypted_ach_routing_number, ' 123456789 ')).to(eq('123456789')) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:overlength_rules).dependent(:destroy)) }
    it { is_expected.to(have_many(:payment_transactions).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:payments).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:preferred_by_broker_customers).dependent(:destroy)) }
    it { is_expected.to(have_many(:pricing_rules).dependent(:destroy)) }
    it { is_expected.to(have_many(:rates).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:shipments).dependent(:restrict_with_error)) }
  end

  describe 'validations' do
    it { is_expected.to(allow_values(nil, '', '123456789').for(:encrypted_ach_routing_number)) }
    it { is_expected.not_to(allow_values('12345678', '1234567890', '12345678a').for(:encrypted_ach_routing_number)) }
    it { is_expected.not_to(allow_value('12345678').for(:encrypted_ach_routing_number).with_message('must be nine digits')) }
  end
end
