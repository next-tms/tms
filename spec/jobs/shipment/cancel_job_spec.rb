require 'rails_helper'

RSpec.describe(Shipment::CancelJob) do
  describe '#perform' do
    let(:shipment) { create(:shipment, booked_at: nil, canceled_at: nil, dispatched_at: nil) }

    before { described_class.perform_now(shipment) }

    it { expect(shipment.reload.canceled_at).to(be_present) }
    it { expect(shipment.reload.updated_by_id).to(be_nil) }
  end
end
