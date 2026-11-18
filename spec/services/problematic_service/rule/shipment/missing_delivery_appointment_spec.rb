require 'rails_helper'

RSpec.describe(ProblematicService::Rule::Shipment::MissingDeliveryAppointment) do
  describe '#resolvable?' do
    subject { described_class.new(nil).with(shipment).resolvable? }

    let(:shipment) do
      build(
        :shipment,
        canceled_at: nil,
        delivered_at: nil,
        delivery_appointment_at: nil,
        delivery_appointment_on: nil,
        picked_up_at: 1.day.ago
      )
    end

    it { is_expected.to(be(false)) }

    context 'when canceled' do
      before { shipment.canceled_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when delivered' do
      before { shipment.delivered_at = 1.hour.ago }

      it { is_expected.to(be(true)) }
    end

    context 'when delivery appointment at is present' do
      before { shipment.delivery_appointment_at = 1.day.from_now }

      it { is_expected.to(be(true)) }
    end

    context 'when delivery appointment on is present' do
      before { shipment.delivery_appointment_on = Date.tomorrow }

      it { is_expected.to(be(true)) }
    end

    context 'when not picked up' do
      before { shipment.picked_up_at = nil }

      it { is_expected.to(be(true)) }
    end
  end
end
