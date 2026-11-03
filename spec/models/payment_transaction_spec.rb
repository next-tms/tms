# == Schema Information
#
# Table name: payment_transactions
#
# @!attribute id
#   @return []
# @!attribute additional_charge
#   @return [Boolean]
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute dsdc_invoice
#   @return [Hash]
# @!attribute due_on
#   @return [Date]
# @!attribute invoice
#   @return [String]
# @!attribute notes
#   @return [String]
# @!attribute paid_cents
#   @return [Integer]
# @!attribute paid_currency
#   @return [String]
# @!attribute pro
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_bill_id
#   @return [Integer]
# @!attribute broker_carrier_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute dsdc_unique_id
#   @return [String]
# @!attribute legacy_load_id
#   @return [String]
# @!attribute payment_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_payment_transactions_on_broker_carrier_id  (broker_carrier_id)
#  index_payment_transactions_on_dsdc_unique_id     (broker_carrier_id,dsdc_unique_id) UNIQUE
#  index_payment_transactions_on_payment_id         (payment_id)
#  index_payment_transactions_on_shipment_id        (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (payment_id => payments.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
require 'rails_helper'

RSpec.describe(PaymentTransaction) do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, :saia, name: 'Saia') }
  let(:payment_transaction) { build(:payment_transaction, broker_carrier:, paid_cents: 12_345, shipment:) }
  let(:shipment) { create(:shipment, broker_carrier:, load_id: 42, pro: '12345678901') }

  before { create(:setting, key: 'name', value: 'Acme Freight') }

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(eq(['shipment'])) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('id', 'legacy_load_id', 'notes')) }
    it { expect(described_class.ransackable_attributes).not_to(include('balance_cents', 'paid_cents')) }
  end

  describe '#accounting_bill_line_item' do
    let(:line_item) { payment_transaction.__send__(:accounting_bill_line_item) }

    it { expect(line_item).to(have_attributes(amount: 123.45, kind: :account_based_expense)) }
    it { expect(line_item.description).to(eq('Shipping (Acme Freight Load 42 / Saia Pro 12345678901)')) }
  end

  describe '#accounting_bill_mailing_address' do
    let(:address) { payment_transaction.__send__(:accounting_bill_mailing_address) }

    it { expect(address).to(have_attributes(city: 'Dallas', line1: 'Saia', line2: 'PO Box 730532')) }

    context 'when the account has its own check mailing address' do
      let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address: create(:address, street: '9 Own St')) }

      it { expect(address.line2).to(eq('9 Own St')) }
    end

    context 'when there is no check mailing address' do
      let(:carrier) { create(:carrier) }

      it { expect(address).to(be_nil) }
    end
  end

  describe '#attach_dsdc_documents' do
    let(:payment_transaction) { create(:payment_transaction) }
    let(:pod) { { content_type: 'application/pdf', filename: 'pod.pdf', io: StringIO.new('%PDF-1.4'), metadata: { document_type: 'POD' } } }

    before { payment_transaction.attach_dsdc_documents([pod]) }

    it { expect(payment_transaction.dsdc_documents).to(be_attached) }
    it { expect(payment_transaction.shipment.carrier_pod.blob).to(eq(payment_transaction.dsdc_documents.sole.blob)) }
  end

  describe '#paid?' do
    it { expect(payment_transaction.paid?).to(be(false)) }

    context 'when the payment is paid' do
      before { allow(payment_transaction).to(receive(:payment).and_return(instance_double(Payment, paid?: true))) }

      it { expect(payment_transaction.paid?).to(be(true)) }
    end
  end

  describe '#shipment_load_id' do
    it { expect(payment_transaction.shipment_load_id).to(eq(42)) }

    context 'when there is no shipment' do
      let(:shipment) { nil }

      it { expect(payment_transaction.shipment_load_id).to(be_nil) }
    end
  end

  describe 'validations' do
    let(:payment_transaction) { create(:payment_transaction, dsdc_unique_id: 'INV-1') }

    it { expect(build(:payment_transaction, broker_carrier: payment_transaction.broker_carrier, dsdc_unique_id: 'INV-1')).not_to(be_valid) }
    it { expect(build(:payment_transaction, dsdc_unique_id: 'INV-1')).to(be_valid) }
    it { expect(build(:payment_transaction, broker_carrier: payment_transaction.broker_carrier, dsdc_unique_id: nil)).to(be_valid) }
  end
end
