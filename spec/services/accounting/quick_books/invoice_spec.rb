require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Invoice do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Invoice.new }

  before { allow(Quickbooks::Service::Invoice).to receive(:new).and_return(service) }

  describe '#save' do
    subject(:saved) { invoice.save }

    let(:invoice) do
      described_class.new(
        customer_id: '5',
        document_number: '1001',
        line_items: [
          Accounting::LineItem.new(description: 'Shipper Ref: ABC'),
          Accounting::LineItem.new(amount: 250.0, description: 'Freight', kind: :sales, quantity: 1, unit_price: 250.0)
        ],
        shipping_method: 'A Very Long Carrier Name That Exceeds Thirty-One Characters'
      )
    end

    before { allow(service).to receive(:create) { |record| record.tap { it.id = '77' } } }

    it 'serializes the header fields' do
      saved

      expect(service).to(have_received(:create) do |model|
        expect(model.customer_ref.value).to eq('5')
        expect(model.doc_number.to_s).to eq('1001')
      end)
    end

    it 'truncates the ship method to QuickBooks 31-character limit' do
      saved

      expect(service).to(have_received(:create) { |model| expect(model.ship_method_ref.value.length).to eq(31) })
    end

    it 'maps each line item to a QuickBooks line item' do
      saved

      expect(service).to(have_received(:create) do |model|
        expect(model.line_items.map(&:detail_type)).to contain_exactly('DescriptionOnly', 'SalesItemLineDetail')
      end)
    end
  end

  describe '#save when the document number already exists' do
    subject(:saved) { described_class.new(document_number: '1001').save }

    let(:existing) { Quickbooks::Model::Invoice.new(doc_number: '1001').tap { it.id = '88' } }

    before do
      allow(service).to receive(:create).and_raise(Quickbooks::IntuitRequestException.new('Duplicate Document Number Error'))
      allow(service).to receive(:find_by).and_return([existing])
    end

    it { expect(saved.id).to eq('88') }
  end
end
