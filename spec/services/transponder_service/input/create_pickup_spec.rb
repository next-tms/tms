require 'rails_helper'

RSpec.describe(TransponderService::Input::CreatePickup) do
  describe '#build' do
    let(:pickup) { create(:pickup, rate:, shipment:) }
    let(:rate) { create(:rate, declared_freight_classes: true, reference: 'Q-12345', shipment:) }
    let(:shipment) { create(:shipment) }

    before do
      allow(TransponderService::Input::Contact).to(receive(:call))
      allow(TransponderService::Input::Shipment).to(receive(:call))

      described_class.new(pickup).build
    end

    it { expect(TransponderService::Input::Shipment).to(have_received(:call).with(shipment, declared_freight_classes: true, estimate_reference: 'Q-12345')) }
  end
end
