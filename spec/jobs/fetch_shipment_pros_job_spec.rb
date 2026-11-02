require 'rails_helper'

RSpec.describe(FetchShipmentProsJob) do
  describe '#perform' do
    let(:broker_carrier) { create(:broker_carrier) }
    let!(:shipment) { create(:shipment, broker_carrier:, dispatched_at: 1.day.ago, picked_up_at: nil, pickup_confirmation: '123') }
    let!(:unconfirmed_shipment) do
      create(:shipment, broker_carrier:, dispatched_at: 1.day.ago, picked_up_at: nil, pickup_confirmation: nil)
    end

    before { allow(BrokerCarrier).to(receive(:api_configured).and_return(BrokerCarrier.all)) }

    it { expect { described_class.perform_now }.to(have_enqueued_job(FetchShipmentProJob).with(shipment)) }
    it { expect { described_class.perform_now }.not_to(have_enqueued_job(FetchShipmentProJob).with(unconfirmed_shipment)) }
  end
end
