require 'rails_helper'

RSpec.describe(Shipment::TrackJob) do
  describe '#perform' do
    let(:shipment) { build(:shipment) }

    before do
      allow(shipment).to(receive(:update_tracking_events))
      described_class.perform_now(shipment)
    end

    it { expect(shipment).to(have_received(:update_tracking_events)) }
  end
end
