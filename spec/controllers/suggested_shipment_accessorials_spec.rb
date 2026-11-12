require 'rails_helper'

RSpec.describe(SuggestedShipmentAccessorials) do
  describe '#build_suggested_broker_accessorials' do
    subject(:suggested_broker_accessorials) { controller.build_suggested_broker_accessorials(shipment:) }

    let(:accessorials_has_been_suggested) { nil }
    let(:broker_accessorial) { create(:broker_accessorial, accessorial: nil, broker_customer: nil, code: 'DLIF', name: 'Liftgate') }
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
    let(:suggested) { shipment.shipment_broker_accessorials.select(&:suggested) }

    before do
      [shipment.receiver_address, shipment.shipper_address].each do |address|
        allow(address).to(receive(:find_or_build_standardized_address))
        allow(address).to(receive(:standardized_address).and_return(nil))
      end
      allow(shipment).to(receive(:suggested_broker_accessorials).and_return([broker_accessorial]))
    end

    it { is_expected.to(eq([broker_accessorial])) }

    context 'when called' do
      before { suggested_broker_accessorials }

      it { expect(shipment.receiver_address).to(have_received(:find_or_build_standardized_address)) }
      it { expect(shipment.shipper_address).to(have_received(:find_or_build_standardized_address)) }
      it { expect(suggested.map(&:broker_accessorial)).to(eq([broker_accessorial])) }
    end

    context 'when accessorials were already suggested' do
      let(:accessorials_has_been_suggested) { 'true' }

      it { is_expected.to(eq([])) }
    end

    context 'when the request is JSON' do
      let(:format) { :json }

      before { suggested_broker_accessorials }

      it { is_expected.to(eq([])) }
      it { expect(shipment.receiver_address).to(have_received(:find_or_build_standardized_address)) }
      it { expect(suggested).to(be_empty) }
    end

    context 'when the shipment already has the accessorial' do
      before { shipment.shipment_broker_accessorials.build(broker_accessorial:) }

      it { is_expected.to(eq([])) }
    end

    context 'when the shipment is quote only' do
      let(:quote_only) { true }

      before { suggested_broker_accessorials }

      it { is_expected.to(eq([])) }
      it { expect(shipment.receiver_address).not_to(have_received(:find_or_build_standardized_address)) }
    end
  end
end
