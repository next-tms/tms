require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::MissingDeliveryEta) do
  describe '#resolvable?' do
    subject { described_class.new(nil).with(shipment).resolvable? }

    let(:shipment) { build(:shipment, canceled_at: nil, delivered_at: nil, delivery_eta_on: nil, picked_up_at: 1.day.ago) }

    it { is_expected.to(be(false)) }

    context 'when canceled' do
      before { shipment.canceled_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when delivered' do
      before { shipment.delivered_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when delivery ETA is present' do
      before { shipment.delivery_eta_on = Date.tomorrow }

      it { is_expected.to(be(true)) }
    end

    context 'when not picked up' do
      before { shipment.picked_up_at = nil }

      it { is_expected.to(be(true)) }
    end
  end
end
