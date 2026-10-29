require 'rails_helper'

RSpec.describe(Shipment::UnbookJob) do
  describe '#perform' do
    let(:shipment) { create(:shipment, canceled_at: nil) }

    before { described_class.perform_now(shipment) }

    it { expect(shipment.reload.booked_at).to(be_nil) }
    it { expect(shipment.reload.canceled_at).to(be_nil) }
  end
end
