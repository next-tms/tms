require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::MissingPickedUpAt) do
  describe '#resolvable?' do
    subject { described_class.new(nil).with(shipment).resolvable? }

    let(:shipment) { build(:shipment, booked_at: 1.day.ago, delivered_at: nil, dispatched_at: 1.hour.ago, picked_up_at: nil) }

    it { is_expected.to(be(false)) }

    context 'when booked but not dispatched' do
      let(:shipment) { build(:shipment, booked_at: 1.day.ago, delivered_at: nil, dispatched_at: nil, picked_up_at: nil) }

      it { is_expected.to(be(true)) }
    end

    context 'when picked up' do
      let(:shipment) { build(:shipment, booked_at: 1.day.ago, delivered_at: nil, dispatched_at: 1.hour.ago, picked_up_at: 1.minute.ago) }

      it { is_expected.to(be(true)) }
    end
  end
end
