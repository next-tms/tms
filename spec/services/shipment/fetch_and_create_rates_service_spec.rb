require 'rails_helper'

RSpec.describe(Shipment::FetchAndCreateRatesService) do
  shared_examples_for 'fetch and create rates' do
    context 'when shipment has existing rates for all broker carriers valid for quotation' do
      let(:broker_carrier) { create(:broker_carrier) }
      let!(:rate) { create(:rate, shipment:, broker_carrier:) }

      before do
        allow(Rate)
          .to(
            receive(:find_by)
            .with(
              broker_carrier:,
              declared_freight_classes: false,
              shipment_fingerprint:,
              shipment:
            )
            .and_return(rate)
          )

        allow(shipment).to(receive(:valid_broker_carriers_for_quotation).with(user_type).and_return([broker_carrier]))
      end

      it { expect(subject.rates_declared_freight_classes_true).to(eq([])) }
      it { expect(subject.rates_declared_freight_classes_false).to(eq([rate])) }
      it { expect(subject.populate_rate_jobs_on_queue).to(be(false)) }
    end

    context 'when shipment has existing rates and has no rates for other broker carriers' do
      let(:broker_carrier) { create(:broker_carrier) }
      let(:broker_carrier2) { create(:broker_carrier) }
      let!(:rate) do
        create(:rate, shipment:, broker_carrier:, declared_freight_classes: false, shipment_fingerprint: shipment.fingerprint)
      end

      before do
        allow(shipment).to(receive(:valid_broker_carriers_for_quotation).with(user_type).and_return([broker_carrier, broker_carrier2]))
      end

      it { expect(subject.rates_declared_freight_classes_true).to(eq([])) }
      it { expect(subject.rates_declared_freight_classes_false).to(eq([rate])) }
      it { expect(subject.populate_rate_jobs_on_queue).to(be(true)) }
    end
  end

  describe '#call' do
    subject { described_class.new(shipment, shipment_fingerprint:, user_type:).call }

    let(:shipment) { create(:shipment) }
    let(:shipment_fingerprint) { shipment.fingerprint }

    context 'when user type is broker' do
      let(:user_type) { :broker }

      it_behaves_like 'fetch and create rates'
    end

    context 'when user type is customer' do
      let(:user_type) { :customer }

      it_behaves_like 'fetch and create rates'
    end
  end
end
