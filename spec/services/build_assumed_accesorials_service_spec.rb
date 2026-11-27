require 'rails_helper'

RSpec.describe(BuildAssumedAccesorialsService) do
  describe '#call' do
    subject { described_class.new(shipment:).call.map(&:transponder_code) }

    let(:dock) { nil }
    let(:receiver_types) { [] }
    let(:shipment) { create(:shipment, :usd, broker_carrier: nil, receiver_address: build(:address, dock:, name: 'Acme')) }
    let(:shipper_types) { [] }
    let(:weight) { 100 }

    before do
      create(:item, quantity: 1, shipment:, weight:) if weight
      allow(shipment.receiver_address).to(receive(:types).and_return(receiver_types))
      allow(shipment.shipper_address).to(receive(:types).and_return(shipper_types))
    end

    it { is_expected.to(eq([])) }

    context 'when a heavy shipment goes to a hospital' do
      let(:receiver_types) { ['hospital'] }
      let(:weight) { 200 }

      it { is_expected.to(eq(['liftgate_delivery'])) }

      context 'with a dock' do
        let(:dock) { true }

        it { is_expected.to(eq([])) }
      end
    end

    context 'when a heavy shipment goes to a place without a dock' do
      let(:dock) { false }
      let(:weight) { 200 }

      it { is_expected.to(eq(['liftgate_delivery'])) }
    end

    context 'when a heavy shipment goes to a residence' do
      let(:weight) { 200 }

      before { allow(shipment.receiver_address).to(receive(:residential?).and_return(true)) }

      it { is_expected.to(eq(['residential_delivery', 'appointment_delivery', 'liftgate_delivery'])) }

      context 'with a dock' do
        let(:dock) { true }

        it { is_expected.to(eq(['residential_delivery', 'appointment_delivery', 'liftgate_delivery'])) }
      end
    end

    context 'when a heavy shipment goes to a restaurant' do
      let(:weight) { 200 }

      before { allow(shipment.receiver_address).to(receive(:restaurant?).and_return(true)) }

      it { is_expected.to(eq(['liftgate_delivery', 'restaurant_delivery'])) }
    end

    context 'when a heavy shipment is picked up at a mall' do
      let(:shipper_types) { ['mall'] }
      let(:weight) { 200 }

      it { is_expected.to(eq(['liftgate_pickup'])) }
    end

    context 'when a light shipment goes to a mall' do
      let(:receiver_types) { ['mall'] }

      it { is_expected.to(eq([])) }
    end

    context 'when a light shipment goes to a place without a dock' do
      let(:dock) { false }

      it { is_expected.to(eq([])) }
    end

    context 'when the broker customer overrides an accessorial' do
      let!(:customer) do
        create(:accessorial, broker_customer: shipment.broker_customer, code: 'CLIF', transponder_code: 'liftgate_delivery')
      end
      let(:receiver_types) { ['hospital'] }
      let(:weight) { 200 }

      it { expect(described_class.new(shipment:).call).to(eq([customer])) }
    end

    context 'when the shipment has no items' do
      let(:receiver_types) { ['hospital'] }
      let(:weight) { nil }

      it { is_expected.to(eq([])) }
    end

    context 'when the shipment already has residential delivery' do
      let(:weight) { 200 }

      before do
        allow(shipment).to(receive(:selected_accessorials).and_return([build(:accessorial, transponder_code: 'residential_delivery')]))
      end

      it { is_expected.to(eq(['residential_delivery', 'appointment_delivery', 'liftgate_delivery'])) }
    end
  end
end
