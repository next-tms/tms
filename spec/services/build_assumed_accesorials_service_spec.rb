require 'rails_helper'

RSpec.describe(BuildAssumedAccesorialsService) do
  describe '#call' do
    subject { described_class.new(shipment:).call.map(&:code) }

    let(:codes) { ['DAPP', 'DLIF', 'DRES', 'DRST', 'PLIF'] }
    let(:dock) { nil }
    let(:receiver_types) { [] }
    let(:shipment) { create(:shipment, :usd, broker_carrier: nil, receiver_address: build(:address, dock:, name: 'Acme')) }
    let(:shipper_types) { [] }
    let(:weight) { 100 }

    before do
      codes.each { |code| create(:accessorial, code:, name: code) }
      create(:item, quantity: 1, shipment:, weight:) if weight
      allow(shipment.receiver_address).to(receive(:types).and_return(receiver_types))
      allow(shipment.shipper_address).to(receive(:types).and_return(shipper_types))
    end

    it { is_expected.to(eq([])) }

    context 'when a heavy shipment goes to a hospital' do
      let(:receiver_types) { ['hospital'] }
      let(:weight) { 200 }

      it { is_expected.to(eq(['DLIF'])) }

      context 'with a dock' do
        let(:dock) { true }

        it { is_expected.to(eq([])) }
      end
    end

    context 'when a heavy shipment goes to a place without a dock' do
      let(:dock) { false }
      let(:weight) { 200 }

      it { is_expected.to(eq(['DLIF'])) }
    end

    context 'when a heavy shipment goes to a residence' do
      let(:weight) { 200 }

      before { allow(shipment.receiver_address).to(receive(:residential?).and_return(true)) }

      it { is_expected.to(eq(['DRES', 'DAPP', 'DLIF'])) }

      context 'with a dock' do
        let(:dock) { true }

        it { is_expected.to(eq(['DRES', 'DAPP', 'DLIF'])) }
      end
    end

    context 'when a heavy shipment goes to a restaurant' do
      let(:weight) { 200 }

      before { allow(shipment.receiver_address).to(receive(:restaurant?).and_return(true)) }

      it { is_expected.to(eq(['DLIF', 'DRST'])) }
    end

    context 'when a heavy shipment is picked up at a mall' do
      let(:shipper_types) { ['mall'] }
      let(:weight) { 200 }

      it { is_expected.to(eq(['PLIF'])) }
    end

    context 'when a light shipment goes to a mall' do
      let(:receiver_types) { ['mall'] }

      it { is_expected.to(eq([])) }
    end

    context 'when a light shipment goes to a place without a dock' do
      let(:dock) { false }

      it { is_expected.to(eq([])) }
    end

    context 'when an accessorial is missing' do
      let(:codes) { ['DAPP', 'DRES', 'DRST', 'PLIF'] }
      let(:receiver_types) { ['hospital'] }
      let(:weight) { 200 }

      it { is_expected.to(eq([])) }
    end

    context 'when the shipment has no items' do
      let(:receiver_types) { ['hospital'] }
      let(:weight) { nil }

      it { is_expected.to(eq([])) }
    end

    context 'when the shipment already has residential delivery' do
      let(:weight) { 200 }

      before { allow(shipment).to(receive(:accessorial_codes).and_return(['DRES'])) }

      it { is_expected.to(eq(['DRES', 'DAPP', 'DLIF'])) }
    end
  end
end
