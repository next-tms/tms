require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::MissingCarrierTrackingPro) do
  describe '#resolvable?' do
    subject { described_class.new(nil).with(shipment).resolvable? }

    let(:shipment) { build(:shipment, delivered_at: nil, tracking_carrier:, tracking_carrier_pro: nil) }
    let(:tracking_carrier) { build(:carrier) }

    it { is_expected.to(be(false)) }

    context 'when booked but not dispatched' do
      let(:shipment) { build(:shipment, delivered_at: nil, dispatched_at: nil, tracking_carrier:, tracking_carrier_pro: nil) }

      it { is_expected.to(be(true)) }
    end

    context 'when tracking_carrier_pro is present' do
      let(:shipment) { build(:shipment, delivered_at: nil, tracking_carrier:, tracking_carrier_pro: '123') }

      it { is_expected.to(be(true)) }
    end
  end
end
