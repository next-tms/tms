require 'rails_helper'

RSpec.describe(Shipment::CancelManyJob) do
  describe '#perform' do
    let!(:recent_shipment) { create(:shipment, broker_carrier: nil) }
    let!(:stale_shipment) { create(:shipment, broker_carrier: nil).tap { |shipment| shipment.update_columns(updated_at: 22.days.ago) } }

    before { described_class.perform_now }

    it { expect(Shipment::CancelJob).to(have_been_enqueued.with(stale_shipment)) }
    it { expect(Shipment::CancelJob).not_to(have_been_enqueued.with(recent_shipment)) }
  end
end
