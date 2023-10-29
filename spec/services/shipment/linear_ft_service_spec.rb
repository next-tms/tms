# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::LinearFtService) do
  let!(:shipment) { create(:shipment) }
  let!(:items) do
    [
      create(:item, quantity: 1, l: 48, w: 36, h: 24),
      create(:item, quantity: 1, l: 60, w: 48, h: 36),
      create(:item, quantity: 1, l: 36, w: 24, h: 12),
    ]
  end

  before do
    shipment.items = items
    shipment.save
  end

  describe '#call' do
    let(:instance) { described_class.new(shipment) }
    let(:trailer_length) { described_class::DEFAULT_TRAILER_LENGTH }

    it { expect(instance.call(trailer_length)).to(eq(Measured::Length.new(4, :ft))) }

    context 'when any item is missing length, width and/or height' do
      let(:items) { [create(:item), create(:item, l: nil)] }

      it { expect { instance.call(trailer_length) }.to(raise_error(Shipment::LinearFtService::UncalculableError)) }
    end
  end
end
