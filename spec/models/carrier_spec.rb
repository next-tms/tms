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
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute encrypted_proxy_url
#   @return [String]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute mc_number
#   @return [Integer]
# @!attribute name
#   @return [String]
# @!attribute scac
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
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(Carrier) do
  subject(:carrier) { described_class.new(scac: 'ZZZZ') }

  let(:freight_kit_class) do
    double(
      bol_requires_tracking_number?: true,
      create_pickup_implemented?: true,
      pickup_number_is_tracking_number?: true,
      required_credential_types: %i[api]
    )
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(eq(%w[name scac])) }
  end

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(eq([])) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:broker_carriers)) }
    it { is_expected.to(have_many(:terminals)) }

    it { is_expected.to(belong_to(:broker_billing_address).required(false)) }
    it { is_expected.to(belong_to(:check_mailing_address).required(false)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:scac).allow_nil) }

    it { is_expected.to(validate_uniqueness_of(:mc_number).allow_nil) }
  end

  describe '#bol_requires_tracking_number?' do
    it { expect(carrier.bol_requires_tracking_number?).to(be(false)) }

    context 'when FreightKit knows the carrier' do
      before { stub_const('FreightKit::ZZZZ', freight_kit_class) }

      it { expect(carrier.bol_requires_tracking_number?).to(be(true)) }
    end
  end

  describe '#create_pickup_implemented?' do
    it { expect(carrier.create_pickup_implemented?).to(be(false)) }

    context 'when FreightKit knows the carrier' do
      before { stub_const('FreightKit::ZZZZ', freight_kit_class) }

      it { expect(carrier.create_pickup_implemented?).to(be(true)) }
    end
  end

  describe '#pickup_number_is_tracking_number?' do
    it { expect(carrier.pickup_number_is_tracking_number?).to(be(false)) }

    context 'when FreightKit knows the carrier' do
      before { stub_const('FreightKit::ZZZZ', freight_kit_class) }

      it { expect(carrier.pickup_number_is_tracking_number?).to(be(true)) }
    end
  end

  describe '#required_freight_kit_credentials' do
    it { expect(carrier.required_freight_kit_credentials).to(eq([])) }

    context 'when FreightKit knows the carrier' do
      before { stub_const('FreightKit::ZZZZ', freight_kit_class) }

      it { expect(carrier.required_freight_kit_credentials).to(eq(%i[api])) }
    end
  end
end
