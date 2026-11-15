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

    context 'when a receivable is sent' do
      let(:broker_customer) do
        create(:broker_customer, requires_carrier_bol_on_receivables: false, requires_carrier_pod_on_receivables: false)
      end
      let(:shipment) { create(:shipment, broker_customer:, delivered_at: nil, tracking_carrier:, tracking_carrier_pro: nil) }

      before { create(:receivable, sent_at: 1.day.ago, shipment:) }

      it { is_expected.to(be(true)) }
    end

    context 'when tracking_carrier_pro is present' do
      let(:shipment) { build(:shipment, delivered_at: nil, tracking_carrier:, tracking_carrier_pro: '123') }

      it { is_expected.to(be(true)) }
    end
  end
end
