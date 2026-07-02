require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Bill do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Bill.new }

  before { allow(Quickbooks::Service::Bill).to receive(:new).and_return(service) }

  describe '#save' do
    subject(:saved) { bill.save }

    let(:bill) do
      described_class.new(
        document_number: '1001',
        line_items: [ Accounting::LineItem.new(amount: 500.0, description: 'Shipping', kind: :account_based_expense) ],
        vendor_id: '8',
      )
    end

    before { allow(service).to receive(:create) { |record| record.tap { it.id = '21' } } }

    it 'serializes the header and an account-based expense line item' do
      saved

      expect(service).to(have_received(:create) do |model|
        expect(model.doc_number.to_s).to eq('1001')
        expect(model.vendor_ref.value).to eq('8')
        expect(model.line_items.map(&:detail_type)).to eq([ 'AccountBasedExpenseLineDetail' ])
      end)
    end

    it { expect { saved }.to change(bill, :persisted?).from(false).to(true) }
  end

  describe '#save when the document number already exists' do
    subject(:saved) { described_class.new(document_number: '1001').save }

    let(:existing) { Quickbooks::Model::Bill.new(doc_number: '1001').tap { it.id = '99' } }

    before do
      allow(service).to receive(:create).and_raise(Quickbooks::IntuitRequestException.new('Duplicate Document Number Error'))
      allow(service).to receive(:find_by).and_return([ existing ])
    end

    it { expect(saved.id).to eq('99') }
  end
end
