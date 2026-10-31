# == Schema Information
#
# Table name: broker_carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute account
#   @return [String]
# @!attribute account_desc
#   @return [String]
# @!attribute accounting_notes
#   @return [String]
# @!attribute create_invoice_on_pickup
#   @return [Boolean]
# @!attribute days_to_pay_after_invoice_date
#   @return [Integer]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute encrypted_ach_account_number
#   @return [String]
# @!attribute encrypted_ach_bank_name
#   @return [String]
# @!attribute encrypted_ach_routing_number
#   @return [String]
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute ignore_bol_requires_tracking_number
#   @return [Boolean]
# @!attribute password
#   @return [String]
# @!attribute quote_padding_cents
#   @return [Integer]
# @!attribute quote_padding_currency
#   @return [String]
# @!attribute shipments_count
#   @return [Integer]
# @!attribute username
#   @return [String]
# @!attribute website_password
#   @return [String]
# @!attribute website_username
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_vendor_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute carrier_id
#   @return [Integer]
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_broker_carriers_on_broker_customer_id        (broker_customer_id)
#  index_broker_carriers_on_carrier_id                (carrier_id)
#  index_broker_carriers_on_check_mailing_address_id  (check_mailing_address_id)
#  index_broker_carriers_on_shipments_count           (shipments_count)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(BrokerCarrier) do
  subject { build(:broker_carrier) }

  it_behaves_like 'accounting_syncable', resource: :vendor, record: 'Accounting::QuickBooks::Vendor'
  it_behaves_like 'companyable'

  describe '.encrypted_attributes' do
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_account_number)) }
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_bank_name)) }
    it { expect(described_class.encrypted_attributes).to(include(:encrypted_ach_routing_number)) }
  end

  describe '#ach?' do
    it { expect(build(:broker_carrier, encrypted_ach_account_number: '1234', encrypted_ach_routing_number: '123456789')).to(be_ach) }
    it { expect(build(:broker_carrier, encrypted_ach_account_number: '1234')).not_to(be_ach) }
    it { expect(build(:broker_carrier, encrypted_ach_routing_number: '123456789')).not_to(be_ach) }
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
