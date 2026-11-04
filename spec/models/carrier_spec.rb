# == Schema Information
#
# Table name: carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute acts_as_broker
#   @return [Boolean]
# @!attribute consider_bol_and_pod_documents_same
#   @return [Boolean]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute legal_name
#   @return [String]
# @!attribute mc_number
#   @return [Integer]
# @!attribute name
#   @return [String]
# @!attribute scac
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute transponder_id
#   @return [String]
# @!attribute broker_billing_address_id
#   @return []
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_mc_number                  (mc_number) UNIQUE
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#  index_carriers_on_transponder_id             (transponder_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#

require 'rails_helper'

RSpec.describe(Carrier) do
  subject(:carrier) { described_class.new }

  let(:saia) { build(:carrier, :saia) }
  let(:tql) { build(:carrier, :tql) }

  it_behaves_like 'companyable'

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('name', 'scac')) }
    it { expect(described_class.ransackable_attributes).not_to(include('encrypted_api_key', 'encrypted_proxy_url')) }
  end

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(eq([])) }
  end

  describe '.terminals_in' do
    let(:carriers) { described_class.where(id: [local_carrier.id, saia.id]) }
    let(:local_carrier) { create(:carrier) }
    let!(:local_terminal) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier: local_carrier) }
    let(:saia) { create(:carrier, :saia) }

    before { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-CA'), carrier: local_carrier) }

    it { expect(carriers.terminals_in(city: 'austin', state: 'Texas')).to(eq([local_terminal, *saia.transponder_terminals])) }
    it { expect(carriers.terminals_in(city: 'austin', state: 'tx').size).to(eq(2)) }
    it { expect(carriers.terminals_in(city: 'dallas', state: 'TX')).to(eq([])) }
    it { expect(described_class.where(id: local_carrier.id).terminals_in(city: 'Austin', state: 'TX')).to(eq([local_terminal])) }
  end

  describe '.with_api' do
    let!(:custom_carrier) { create(:carrier) }
    let!(:saia) { create(:carrier, :saia) }

    it { expect(described_class.with_api).to(contain_exactly(saia)) }
    it { expect(described_class.with_api).not_to(include(custom_carrier)) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:broker_carriers).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:terminals).dependent(:destroy)) }

    it { is_expected.to(have_many(:payment_transactions).through(:broker_carriers)) }
    it { is_expected.to(have_many(:payments).through(:broker_carriers)) }
    it { is_expected.to(have_many(:shipments).through(:broker_carriers)) }

    it { is_expected.to(belong_to(:broker_billing_address).required(false)) }
    it { is_expected.to(belong_to(:check_mailing_address).required(false)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:scac).allow_nil) }

    it { is_expected.to(validate_uniqueness_of(:mc_number).allow_nil) }
    it { is_expected.to(validate_uniqueness_of(:transponder_id).ignoring_case_sensitivity.allow_nil) }
  end

  describe '#bol_requires_tracking_number?' do
    it { expect(carrier.bol_requires_tracking_number?).to(be_nil) }
    it { expect(saia.bol_requires_tracking_number?).to(be(true)) }
    it { expect(tql.bol_requires_tracking_number?).to(be(false)) }
  end

  describe '#create_pickup_implemented?' do
    it { expect(carrier.create_pickup_implemented?).to(be_nil) }
    it { expect(saia.create_pickup_implemented?).to(be(true)) }
    it { expect(tql.create_pickup_implemented?).to(be(false)) }
  end

  describe '#find_rates_implemented?' do
    it { expect(carrier.find_rates_implemented?).to(be_nil) }
    it { expect(saia.find_rates_implemented?).to(be(true)) }
  end

  describe '#find_rates_with_declared_value?' do
    it { expect(carrier.find_rates_with_declared_value?).to(be_nil) }
    it { expect(saia.find_rates_with_declared_value?).to(be(false)) }
    it { expect(tql.find_rates_with_declared_value?).to(be(true)) }
  end

  describe '#headquarters' do
    it { expect(carrier.headquarters).to(be_nil) }
    it { expect(saia.headquarters.city).to(eq('Johns Creek')) }
  end

  describe '#pickup_number_is_tracking_number?' do
    it { expect(carrier.pickup_number_is_tracking_number?).to(be_nil) }
    it { expect(saia.pickup_number_is_tracking_number?).to(be(false)) }
    it { expect(tql.pickup_number_is_tracking_number?).to(be(true)) }
  end

  describe '#rates_with_excessive_length_fees?' do
    it { expect(carrier.rates_with_excessive_length_fees?).to(be_nil) }
    it { expect(saia.rates_with_excessive_length_fees?).to(be(true)) }
    it { expect(tql.rates_with_excessive_length_fees?).to(be(false)) }
  end

  describe '#required_credential_types' do
    it { expect(carrier.required_credential_types).to(eq([])) }
    it { expect(saia.required_credential_types).to(eq(%i[api])) }
    it { expect(tql.required_credential_types).to(eq(%i[api_key api_proxy])) }
  end

  describe '#transponder_carrier' do
    it { expect(carrier.transponder_carrier).to(be_nil) }
    it { expect(saia.transponder_carrier).to(eq(Transponder::ORM::Carrier.find(saia.transponder_id))) }

    context 'when Transponder no longer has the carrier' do
      before { saia.transponder_id = '00000000-0000-0000-0000-000000000000' }

      it { expect(saia.transponder_carrier).to(have_attributes(id: saia.transponder_id, required_credential_types: [])) }
      it { expect(saia).not_to(be_valid) }
    end

    context 'when the carrier is custom' do
      before do
        allow(Transponder::ORM::Carrier).to(receive(:find_or_initialize_by))
        carrier.transponder_carrier
      end

      it { expect(Transponder::ORM::Carrier).not_to(have_received(:find_or_initialize_by)) }
    end
  end

  describe '#transponder_check_mailing_addresses' do
    it { expect(carrier.transponder_check_mailing_addresses).to(be_nil) }
    it { expect(saia.transponder_check_mailing_addresses.map(&:city)).to(eq(['Dallas'])) }
    it { expect(tql.transponder_check_mailing_addresses).to(eq([])) }
  end

  describe '#transponder_contacts' do
    it { expect(carrier.transponder_contacts).to(be_nil) }
    it { expect(saia.transponder_contacts.map(&:department)).to(eq(['Dispatch'])) }
  end

  describe '#transponder_terminals' do
    it { expect(carrier.transponder_terminals).to(be_nil) }
    it { expect(saia.transponder_terminals.map(&:phone)).to(eq(['+15125550100'])) }
  end

  describe '#us_dot_number' do
    it { expect(carrier.us_dot_number).to(be_nil) }
    it { expect(saia.us_dot_number).to(eq('29124')) }
  end

  describe '#valid_tracking_number?' do
    it { expect(carrier.valid_tracking_number?('abc')).to(be(true)) }
    it { expect(saia.valid_tracking_number?('12345678901')).to(be(true)) }
    it { expect(saia.valid_tracking_number?('abc')).to(be(false)) }
    it { expect(tql.valid_tracking_number?('abc')).to(be(true)) }
  end

  describe '#website_url' do
    it { expect(carrier.website_url).to(be_nil) }
    it { expect(saia.website_url).to(eq('https://www.saia.com')) }
  end
end
