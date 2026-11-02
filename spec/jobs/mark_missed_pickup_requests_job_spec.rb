require 'rails_helper'

RSpec.describe(MarkMissedPickupRequestsJob) do
  describe '#perform' do
    let(:missed_shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago) }
    let!(:missed_pickup_request) { create(:pickup_request, shipments: [missed_shipment]) }
    let(:unassigned_shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: nil, pickup_on: 2.days.ago) }
    let!(:unassigned_pickup_request) { create(:pickup_request, shipments: [unassigned_shipment]) }

    before do
      create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
      described_class.perform_now
    end

    it { expect(missed_pickup_request.reload.reschedule_reason).to(eq('missed')) }
    it { expect(missed_shipment.reload.pickup_driver_assigned_at).to(be_nil) }
    it { expect(unassigned_pickup_request.reload.reschedule_reason).to(be_nil) }
  end
end
