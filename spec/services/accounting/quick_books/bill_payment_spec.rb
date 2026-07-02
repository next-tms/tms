require 'rails_helper'

RSpec.describe Accounting::QuickBooks::BillPayment do
  let!(:integration) { create(:integration) }
  let(:service) { Quickbooks::Service::BillPayment.new }

  before { allow(Quickbooks::Service::BillPayment).to receive(:new).and_return(service) }

  describe '#save' do
    subject(:saved) { bill_payment.save }

    let(:bill_payment) do
      described_class.new(
        account_id: '5',
        account_name: 'Operating',
        document_number: '900',
        line_items: [
          Accounting::LineItem.new(amount: 250.0, description: 'PRO123', linked_transactions: [ { txn_id: '88', txn_type: 'Bill' } ])
        ],
        pay_type: :check,
        total: 250.0,
        vendor_id: '8',
      )
    end

    before { allow(service).to receive(:create) { |model| model.tap { it.id = '301' } } }

    it { is_expected.to have_attributes(id: '301') }

    it 'serializes a check payment with the bank-account ref, vendor, and linked-transaction line item' do
      saved

      expect(service).to(have_received(:create) do |model|
        expect(model.pay_type).to eq('Check')
        expect(model.check_payment.bank_account_ref.value).to eq('5')
        expect(model.vendor_ref.value).to eq('8')
        expect(model.line_items.first.linked_transactions.first.txn_id).to eq('88')
      end)
    end
  end
end
