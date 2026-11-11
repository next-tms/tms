require 'rails_helper'

RSpec.describe(PickupRequest) do
  subject!(:pickup_request) { create(:pickup_request, accepted_pickup_on: shipment.pickup_on, shipments: [shipment]) }

  let(:shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: nil, pickup_on: Date.new(2026, 11, 2)) }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  describe '.active' do
    let(:canceled_pickup_request) { create(:pickup_request).tap(&:cancel) }

    it { expect(described_class.active).to(include(pickup_request)) }
    it { expect(described_class.active).not_to(include(canceled_pickup_request)) }
  end

  describe '.audits' do
    before { pickup_request.update!(reschedule_reason: :weather) }

    it { expect(described_class.where(id: pickup_request.id).audits).to(all(have_attributes(auditable_id: pickup_request.id))) }
    it { expect(described_class.where(id: pickup_request.id).audits.count).to(eq(pickup_request.audits.count)) }
    it { expect(described_class.none.audits).to(be_empty) }
  end

  describe '.missed' do
    let(:shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago) }

    it { expect(described_class.missed).to(include(pickup_request)) }

    context 'when canceled' do
      before { pickup_request.cancel }

      it { expect(described_class.missed).not_to(include(pickup_request)) }
    end

    context 'when the freight was picked up' do
      let(:shipment) { create(:shipment, picked_up_at: 2.days.ago, pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago) }

      it { expect(described_class.missed).not_to(include(pickup_request)) }
    end

    context 'when the pickup is today in the configured time zone' do
      let(:shipment) do
        create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 1.hour.ago, pickup_on: Time.find_zone('America/Los_Angeles').today)
      end

      it { expect(described_class.missed).not_to(include(pickup_request)) }
    end

    context 'without a driver assigned' do
      let(:shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: nil, pickup_on: 2.days.ago) }

      it { expect(described_class.missed).not_to(include(pickup_request)) }
    end
  end

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('accepted_pickup_on', 'canceled_at')) }
  end

  describe '#accepted_pickup_at' do
    it { expect(pickup_request.accepted_pickup_at).to(be_within(1.minute).of(Time.current)) }

    context 'when the accepted pickup date changes' do
      before { pickup_request.update!(accepted_pickup_at: 1.day.ago, accepted_pickup_on: Date.new(2026, 11, 3)) }

      it { expect(pickup_request.accepted_pickup_at).to(be_within(1.minute).of(Time.current)) }
    end

    context 'when the accepted pickup date is unchanged' do
      before { pickup_request.update!(accepted_pickup_at: 1.day.ago, reschedule_reason: :weather) }

      it { expect(pickup_request.accepted_pickup_at).to(be_within(1.minute).of(1.day.ago)) }
    end
  end

  describe '#cancel' do
    before { pickup_request.cancel }

    it { is_expected.to(be_canceled) }
  end

  describe '#canceled?' do
    it { is_expected.not_to(be_canceled) }
  end

  describe '#miss!' do
    let(:shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 2.days.ago, pickup_on: Date.new(2026, 10, 30)) }

    around { |example| Timecop.freeze(Time.find_zone('America/Los_Angeles').local(2026, 11, 1, 1)) { example.run } }

    before { pickup_request.miss! }

    it { expect(pickup_request.reschedule_reason).to(eq('missed')) }
    it { expect(pickup_request.status).to(eq('Rescheduled')) }
    it { expect(shipment.reload).to(have_attributes(pickup_driver_assigned_at: nil, pickup_on: Date.new(2026, 11, 2))) }

    context 'with a shipment rescheduled to a future date' do
      subject!(:pickup_request) do
        create(:pickup_request, accepted_pickup_on: shipment.pickup_on, shipments: [rescheduled_shipment, shipment])
      end

      let(:rescheduled_shipment) do
        create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 1.hour.ago, pickup_on: Date.new(2026, 11, 5))
      end

      it { expect(rescheduled_shipment.reload.pickup_on).to(eq(Date.new(2026, 11, 5))) }
      it { expect(rescheduled_shipment.reload.pickup_driver_assigned_at).to(be_present) }
    end

    context 'with a shipment that was picked up' do
      subject!(:pickup_request) do
        create(:pickup_request, accepted_pickup_on: shipment.pickup_on, shipments: [picked_up_shipment, shipment])
      end

      let(:picked_up_shipment) do
        create(:shipment, picked_up_at: 1.day.ago, pickup_driver_assigned_at: 2.days.ago, pickup_on: Date.new(2026, 10, 30))
      end

      it { expect(picked_up_shipment.reload.pickup_on).to(eq(Date.new(2026, 10, 30))) }
    end
  end

  describe '#reschedule_reason' do
    it do
      expect(pickup_request).to(
        define_enum_for(:reschedule_reason)
          .backed_by_column_of_type(:string)
          .with_prefix
          .with_values(described_class::REASONS.index_by(&:itself))
      )
    end
  end

  describe '#reschedule_reason_applicable?' do
    it { is_expected.not_to(be_reschedule_reason_applicable) }

    context 'when the pickup date moves' do
      before { shipment.update!(pickup_on: shipment.pickup_on + 1.day) }

      it { is_expected.to(be_reschedule_reason_applicable) }
    end

    context 'with a reschedule reason' do
      before { pickup_request.update!(reschedule_reason: :weather) }

      it { is_expected.to(be_reschedule_reason_applicable) }
    end
  end

  describe '#rescheduled?' do
    it { is_expected.not_to(be_rescheduled) }

    context 'when the pickup date moves' do
      before { shipment.update!(pickup_on: shipment.pickup_on + 1.day) }

      it { is_expected.to(be_rescheduled) }
    end
  end

  describe '#shipments' do
    it { expect { pickup_request.destroy }.to(raise_error(ActiveRecord::DeleteRestrictionError)) }
  end

  describe '#status' do
    it { expect(pickup_request.status).to(eq('Accepted')) }

    context 'when a driver is assigned' do
      before { shipment.update!(pickup_driver_assigned_at: 1.hour.ago) }

      it { expect(pickup_request.status).to(eq('En Route')) }
    end

    context 'when canceled' do
      before { pickup_request.cancel }

      it { expect(pickup_request.status).to(eq('Cancelled')) }
    end

    context 'when every shipment is picked up' do
      before { shipment.update!(picked_up_at: 1.hour.ago) }

      it { expect(pickup_request.status).to(eq('Departed')) }
    end

    context 'when the pickup date moves' do
      before { shipment.update!(pickup_on: shipment.pickup_on + 1.day) }

      it { expect(pickup_request.status).to(eq('Rescheduled')) }
    end
  end
end
