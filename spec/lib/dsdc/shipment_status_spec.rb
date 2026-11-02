require 'rails_helper'

RSpec.describe(DSDC::ShipmentStatus) do
  subject(:status) { described_class.new(shipment) }

  let(:shipment) { build(:shipment, **attributes) }
  let(:attributes) { {} }

  describe '#all_short_or_lost?' do
    it { is_expected.to(be_all_short_or_lost) }

    context 'when the shipment is not lost' do
      let(:attributes) { { lost_on: nil } }

      it { is_expected.not_to(be_all_short_or_lost) }
    end
  end

  describe '#appointment_status' do
    it { expect(status.appointment_status).to(eq('Secured')) }

    context 'without an appointment' do
      let(:attributes) { { delivery_appointment_at: nil, delivery_appointment_on: nil } }

      it { expect(status.appointment_status).to(be_nil) }
    end
  end

  describe '#cross_border?' do
    it { is_expected.not_to(be_cross_border) }

    context 'when the receiver is in another country' do
      let(:attributes) { { receiver_address: build(:address, country_alpha2: 'CA', region_iso31662: 'CA-ON') } }

      it { is_expected.to(be_cross_border) }
    end
  end

  describe '#estimated_delivery_at' do
    it { expect(status.estimated_delivery_at).to(eq(shipment.quoted_delivery_by)) }
  end

  describe '#latest_tracking_event' do
    let(:attributes) { { tracking_events: [public_tracking_event, private_tracking_event] } }
    let(:private_tracking_event) { build(:tracking_event, at: 1.hour.ago, public: false) }
    let(:public_tracking_event) { build(:tracking_event, at: 2.hours.ago, public: true) }

    it { expect(status.latest_tracking_event).to(equal(public_tracking_event)) }
  end

  describe '#milestone_status' do
    it { expect(status.milestone_status).to(eq('Delivered')) }

    context 'when out for delivery' do
      let(:attributes) { { delivered_at: nil } }

      it { expect(status.milestone_status).to(eq('Out for Delivery')) }
    end

    context 'when departed' do
      let(:attributes) { { delivered_at: nil, out_for_delivery_at: nil } }

      it { expect(status.milestone_status).to(eq('In Transit')) }
    end

    context 'when picked up' do
      let(:attributes) { { delivered_at: nil, departed_origin_terminal_at: nil, out_for_delivery_at: nil } }

      it { expect(status.milestone_status).to(eq('Picked-up')) }
    end

    context 'when not picked up' do
      let(:attributes) { { delivered_at: nil, departed_origin_terminal_at: nil, out_for_delivery_at: nil, picked_up_at: nil } }

      it { expect(status.milestone_status).to(be_nil) }
    end
  end

  describe '#pro_number' do
    it { expect(status.pro_number).to(eq(shipment.load_id.to_s)) }
  end

  describe '#unique_id' do
    let(:attributes) { { created_at: Time.zone.local(2026, 10, 30), load_id: 42 } }

    it { expect(status.unique_id).to(eq('4220261030')) }
  end

  describe '#updated_eta' do
    it { expect(status.updated_eta).to(eq(shipment.delivery_appointment_at)) }

    context 'without an appointment' do
      let(:attributes) { { delivery_appointment_at: nil, delivery_appointment_on: nil } }

      it { expect(status.updated_eta).to(eq(shipment.delivery_eta_on)) }
    end
  end
end
