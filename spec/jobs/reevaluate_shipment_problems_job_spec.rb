require 'rails_helper'

RSpec.describe(ReevaluateShipmentProblemsJob) do
  describe '#perform' do
    subject(:perform) { described_class.perform_now }

    let!(:delivered_shipment) { create_shipment(delivered_at: 1.day.ago, dispatched_at: 3.days.ago, picked_up_at: 2.days.ago) }
    let(:expected_ids) { [pending_delivery_shipment.id, pending_pickup_shipment.id, problematic_shipment.id] }
    let!(:pending_delivery_shipment) { create_shipment(delivered_at: nil, dispatched_at: 3.days.ago, picked_up_at: 2.days.ago) }
    let!(:pending_pickup_shipment) { create_shipment(delivered_at: nil, dispatched_at: 1.day.ago, picked_up_at: nil) }
    let!(:problematic_shipment) { create_shipment(delivered_at: 1.day.ago, dispatched_at: 3.days.ago, picked_up_at: 2.days.ago) }

    before do
      create(:problem, resolvable: delivered_shipment, resolved_at: 1.hour.ago)
      create(:problem, resolvable: problematic_shipment)
    end

    it { expect { perform }.to(have_enqueued_job(ProblematicJob).with(match_array(expected_ids), type: 'Shipment')) }
  end

  def create_shipment(**attributes) = create(:shipment, canceled_at: nil, **attributes).tap { |shipment| shipment.problems.destroy_all }
end
