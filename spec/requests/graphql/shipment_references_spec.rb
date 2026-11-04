require 'rails_helper'

RSpec.describe('GraphQL shipment references') do
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, acts_as_broker: true)) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'X-API-Key' => api_key.token } }
  let(:items) { response.parsed_body.dig('data', 'shipments', 'items') }
  let(:query) { '{ shipments { items { loadId pickupConfirmation pro trackingCarrierPickupConfirmation trackingCarrierPro } } }' }

  let!(:other_shipment) { create(:shipment, broker_customer: create(:broker_customer), pro: 'OTHER-1') }
  let!(:pro_only_shipment) { create(:shipment, broker_carrier:, broker_customer:, pickup_confirmation: 'PU-2', pro: 'ALONE-1') }

  let!(:tracked_shipment) do
    create(
      :shipment,
      broker_carrier:,
      broker_customer:,
      pickup_confirmation: 'PU-1',
      pro: 'BROKER-1',
      tracking_carrier: create(:carrier),
      tracking_carrier_pickup_confirmation: 'TC-PU-1',
      tracking_carrier_pro: 'CARRIER-1'
    )
  end

  before { post('/graphql', headers:, params: { query: }) }

  context 'with a customer API key' do
    let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
    let(:query) { '{ shipments { items { loadId pro } } }' }

    it { expect(items.pluck('loadId')).to(contain_exactly(pro_only_shipment.load_id, tracked_shipment.load_id)) }
    it { expect(items.pluck('pro')).to(contain_exactly('ALONE-1', 'CARRIER-1')) }

    context 'when selecting carrier references' do
      let(:query) { '{ shipments { items { pickupConfirmation trackingCarrierPickupConfirmation trackingCarrierPro } } }' }

      it { expect(response.parsed_body['errors'].pluck('message')).to(all(include("doesn't exist on type 'Shipment'"))) }
      it { expect(response.parsed_body['errors'].size).to(eq(3)) }
    end

    context 'when filtering by the broker carrier PRO' do
      let(:query) { '{ shipments(filter: { proEq: "BROKER-1" }) { items { loadId } } }' }

      it { expect(items).to(be_empty) }
    end

    context 'when filtering by the broker carrier PRO inside or' do
      let(:query) { '{ shipments(filter: { or: [{ proEq: "BROKER-1" }, { trackingCarrierProEq: "BROKER-1" }] }) { items { id } } }' }

      it { expect(items).to(be_empty) }
    end

    context 'when filtering by the tracking carrier PRO' do
      let(:query) { '{ shipments(filter: { proEq: "CARRIER-1" }) { items { loadId } } }' }

      it { expect(items.pluck('loadId')).to(eq([tracked_shipment.load_id])) }
    end

    context 'when filtering by trackingCarrierProEq with the visible PRO' do
      let(:query) { '{ shipments(filter: { trackingCarrierProEq: "CARRIER-1" }) { items { loadId } } }' }

      it { expect(items.pluck('loadId')).to(eq([tracked_shipment.load_id])) }
    end

    context 'when filtering a shipment that only has a PRO' do
      let(:query) { '{ shipments(filter: { proEq: "ALONE-1" }) { items { loadId } } }' }

      it { expect(items.pluck('loadId')).to(eq([pro_only_shipment.load_id])) }
    end

    context "when filtering by another customer's PRO" do
      let(:query) { '{ shipments(filter: { or: [{ proEq: "OTHER-1" }, { loadIdEq: 0 }] }) { items { loadId } } }' }

      it { expect(items).to(be_empty) }
    end

    context 'when filtering by pickup confirmation' do
      let(:query) { '{ shipments(filter: { pickupConfirmationEq: "PU-1" }) { items { loadId } } }' }

      it { expect(response.parsed_body['errors'].first['extensions']).to(eq('code' => 'INVALID_FILTER')) }
      it { expect(response.parsed_body.dig('data', 'shipments')).to(be_nil) }
    end

    context 'when sorting by PRO' do
      let(:query) { '{ shipments(sort: ["pro:desc"]) { items { loadId } } }' }

      it { expect(items.pluck('loadId')).to(eq([tracked_shipment.load_id, pro_only_shipment.load_id])) }
    end
  end

  context 'with a carrier user API key' do
    let(:api_key) { create(:api_key, user: create(:carrier_user, companyable: broker_carrier.carrier)) }

    it { expect(items.pluck('loadId')).to(contain_exactly(pro_only_shipment.load_id, tracked_shipment.load_id)) }
    it { expect(items.pluck('pro')).to(contain_exactly('ALONE-1', 'BROKER-1')) }
    it { expect(items.pluck('trackingCarrierPro')).to(contain_exactly(nil, 'CARRIER-1')) }
    it { expect(items.pluck('pickupConfirmation')).to(contain_exactly('PU-1', 'PU-2')) }

    context "when filtering by another account's PRO" do
      let(:query) { '{ shipments(filter: { or: [{ proEq: "OTHER-1" }] }) { items { loadId } } }' }

      it { expect(items).to(be_empty) }
    end
  end

  context 'with a broker user API key' do
    let(:api_key) { create(:api_key, user: create(:broker_user).tap { |user| user.add_role(:dispatch) }) }

    it { expect(items.pluck('loadId')).to(contain_exactly(other_shipment.load_id, pro_only_shipment.load_id, tracked_shipment.load_id)) }
    it { expect(items.pluck('trackingCarrierPro')).to(include('CARRIER-1')) }
  end
end
