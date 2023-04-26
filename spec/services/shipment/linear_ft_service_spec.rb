# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::LinearFtService) do
  let!(:shipment) { create(:shipment) }
  let!(:item) { create(:item) }

  before do
    shipment.items << item
    shipment.save
  end

  describe '#call' do
    subject { described_class.new(shipment:).call }

    context 'when item does not have length, width and height' do
      before do
        item.update(l: nil, w: nil, h: nil)
      end

      it { expect(subject).to(be_nil) }
    end

    context 'when items are valid' do
      before { item.update(w: 12, l: 12) }

      it 'returns all item width / 12' do
        expect(subject).to(eq(1))
      end

      context 'and items are more than 1' do
        let(:other_item) { create(:item) }

        before do
          other_item.update(w: 20, l: 12)
          shipment.items << other_item
          shipment.save
        end

        it 'returns first item allocated width / 12' do
          expect(subject).to(eq(1))
        end
      end
    end
  end
end
