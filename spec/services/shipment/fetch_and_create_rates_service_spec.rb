# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Shipment::FetchAndCreateRatesService) do
  let(:shipment) { create(:shipment) }
  let(:user_type) { :broker }

  shared_examples_for "fetch and create rates" do
    context 'when shipment has existing rates for all broker carriers valid for quotation' do
      let(:broker_carrier) { create(:broker_carrier) }
      let!(:rate) { create(:rate, shipment: shipment, broker_carrier: broker_carrier) }
      before do
        expect(shipment).to receive(:valid_broker_carriers_for_quotation)
                        .with(user_type: user_type)
                        .and_return([broker_carrier])
        expect(Rate).to receive(:by_shipment_and_broker_carrier)
                    .with(shipment, broker_carrier, false)
                    .and_return(rate)
      end

      it 'returns rates and does not enqueued populate rates job' do
        response = subject

        expect(response.rates_forced_freight_false).to eq([rate])
        expect(response.rates_forced_freight_true).to eq([])
        expect(response.populate_rate_jobs_on_queue).to eq(false)
      end
    end

    context 'when shipment has existing rates and has no rates for other broker carriers' do
      let(:broker_carrier) { create(:broker_carrier) }
      let(:broker_carrier2) { create(:broker_carrier) }
      let!(:rate) do
        create(:rate,
              shipment: shipment,
              broker_carrier: broker_carrier,
              with_calculated_freight_classes: true,
              shipment_fingerprint: shipment.fingerprint)
      end
      before do
        expect(shipment).to receive(:valid_broker_carriers_for_quotation)
                        .with(user_type: user_type)
                        .and_return([broker_carrier, broker_carrier2])
      end

      it 'returns rates and does not enqueued populate rates job' do
        response = subject

        expect(response.rates_forced_freight_false).to eq([rate])
        expect(response.rates_forced_freight_true).to eq([])
        expect(response.populate_rate_jobs_on_queue).to eq(true)
      end
    end
  end
  
  describe '#call' do
    subject { described_class.new(shipment:, user_id: 1, user_type:).call }

    context 'when user type is broker' do
      it_behaves_like 'fetch and create rates'
    end

    context 'when user type is customer' do
      let(:user_type) { :customer }

      it_behaves_like 'fetch and create rates'
    end
  end
end
