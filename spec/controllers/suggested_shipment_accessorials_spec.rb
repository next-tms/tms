require 'rails_helper'

RSpec.describe(SuggestedShipmentAccessorials) do
  describe '#build_suggested_accessorials' do
    subject(:suggested_accessorials) { controller.build_suggested_accessorials(shipment:) }

    let(:accessorials_has_been_suggested) { nil }
    let(:accessorial) { create(:accessorial, broker_customer: nil, code: 'DLIF', name: 'Liftgate') }
    let(:controller) do
      Class.new do
        include SuggestedShipmentAccessorials

        attr_reader :request, :shipment_params

        def initialize(request:, shipment_params:)
          @request = request
          @shipment_params = shipment_params
        end
      end.new(request:, shipment_params: { accessorials_has_been_suggested: })
    end
    let(:format) { :html }
    let(:quote_only) { false }
    let(:request) { instance_double(ActionDispatch::Request, format: Mime[format]) }
    let(:shipment) { build(:shipment, :usd, broker_carrier: nil, quote_only:) }
    let(:suggested) { shipment.shipment_accessorials.select(&:suggested) }

    before do
      [shipment.receiver_address, shipment.shipper_address].each { |address| allow(address).to(receive(:standardize)) }
      allow(shipment).to(receive(:suggested_accessorials).and_return([accessorial]))
    end

    it { is_expected.to(eq([accessorial])) }

    context 'when called' do
      before { suggested_accessorials }

      it { expect(shipment.receiver_address).to(have_received(:standardize)) }
      it { expect(shipment.shipper_address).to(have_received(:standardize)) }
      it { expect(suggested.map(&:accessorial)).to(eq([accessorial])) }
    end

    context 'when accessorials were already suggested' do
      let(:accessorials_has_been_suggested) { 'true' }

      it { is_expected.to(eq([])) }
    end

    context 'when the request is JSON' do
      let(:format) { :json }

      before { suggested_accessorials }

      it { is_expected.to(eq([])) }
      it { expect(shipment.receiver_address).not_to(have_received(:standardize)) }
      it { expect(suggested).to(be_empty) }
    end

    context 'when the shipment is quote only' do
      let(:quote_only) { true }

      before { suggested_accessorials }

      it { is_expected.to(eq([])) }
      it { expect(shipment.receiver_address).not_to(have_received(:standardize)) }
    end
  end
end
