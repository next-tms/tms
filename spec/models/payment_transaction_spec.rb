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
  describe '#attach_dsdc_documents' do
    let(:payment_transaction) { create(:payment_transaction) }
    let(:pod) { { content_type: 'application/pdf', filename: 'pod.pdf', io: StringIO.new('%PDF-1.4'), metadata: { document_type: 'POD' } } }

    before { payment_transaction.attach_dsdc_documents([pod]) }

    it { expect(payment_transaction.dsdc_documents).to(be_attached) }
    it { expect(payment_transaction.shipment.carrier_pod.blob).to(eq(payment_transaction.dsdc_documents.sole.blob)) }
  end

  describe 'validations' do
    let(:payment_transaction) { create(:payment_transaction, dsdc_unique_id: 'INV-1') }

    it { expect(build(:payment_transaction, broker_carrier: payment_transaction.broker_carrier, dsdc_unique_id: 'INV-1')).not_to(be_valid) }
    it { expect(build(:payment_transaction, dsdc_unique_id: 'INV-1')).to(be_valid) }
    it { expect(build(:payment_transaction, broker_carrier: payment_transaction.broker_carrier, dsdc_unique_id: nil)).to(be_valid) }
  end
end
