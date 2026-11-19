require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::Lost) do
  describe '#resolvable?' do
    subject { described_class.new(nil).with(shipment).resolvable? }

    let(:shipment) { build(:shipment, canceled_at: nil, delivered_at: nil, lost_on: Date.yesterday) }

    it { is_expected.to(be(false)) }

    context 'when canceled' do
      before { shipment.canceled_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when delivered' do
      before { shipment.delivered_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when not lost' do
      before { shipment.lost_on = nil }

      it { is_expected.to(be(true)) }
    end
  end
end
