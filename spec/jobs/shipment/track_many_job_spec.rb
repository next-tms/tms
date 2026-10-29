require 'rails_helper'

RSpec.describe(Shipment::TrackManyJob) do
  describe '#perform' do
    let!(:shipment) { create(:shipment) }
    let!(:shipment_without_carrier) { create(:shipment, broker_carrier: nil) }

    before { described_class.perform_now([ shipment.id, shipment_without_carrier.id ]) }

    it { expect(Shipment::TrackJob).to(have_been_enqueued.with(shipment)) }
    it { expect(Shipment::TrackJob).not_to(have_been_enqueued.with(shipment_without_carrier)) }
  end
end
