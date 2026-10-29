require 'rails_helper'

RSpec.describe(Shipment::UnbookManyJob) do
  describe '#perform' do
    let!(:picked_up_shipment) { create(:shipment, booked_at: 2.weeks.ago, dispatched_at: nil) }
    let!(:recently_booked_shipment) { create(:shipment, booked_at: 2.days.ago, dispatched_at: nil, picked_up_at: nil) }
    let!(:stale_shipment) { create(:shipment, booked_at: 2.weeks.ago, dispatched_at: nil, picked_up_at: nil) }

    before { described_class.perform_now }

    it { expect(Shipment::UnbookJob).to(have_been_enqueued.with(stale_shipment)) }
    it { expect(Shipment::UnbookJob).not_to(have_been_enqueued.with(picked_up_shipment)) }
    it { expect(Shipment::UnbookJob).not_to(have_been_enqueued.with(recently_booked_shipment)) }
  end
end
