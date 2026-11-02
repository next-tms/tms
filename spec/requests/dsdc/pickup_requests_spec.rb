require 'rails_helper'

RSpec.describe('DSDC::PickupRequests') do
  let(:api_key) { create(:api_key) }
  let(:body) { JSON.parse(file_fixture('dsdc/pickup_request.json').read.sub('PRO_NUMBER', shipment.load_id.to_s)) }
  let(:headers) { { 'Content-Type' => 'application/json', 'X-API-Key' => api_key.token } }
  let(:json) { response.parsed_body }
  let(:pickup_request) do
    create(:pickup_request, accepted_pickup_on: shipment.pickup_on, created_by: api_key.authorizable, shipments: [shipment])
  end
  let(:shipment) do
    create(:shipment, :usd, broker_customer: api_key.authorizable.companyable, picked_up_at: nil, pickup_driver_assigned_at: nil)
  end

  describe 'DELETE /api/dsdc/v1/pickups/:pickup_id' do
    before { delete("/api/dsdc/v1/pickups/#{pickup_request.id}", headers:) }

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(json.sole).to(include('pickupStatus' => 'Cancelled')) }
    it { expect(pickup_request.reload).to(be_canceled) }
  end

  describe 'GET /api/dsdc/v1/pickups' do
    let(:params) { { isTest: 'false', lookupType: lookup_type, lookupValue: lookup_value, requestType: 'Status' } }

    before { get('/api/dsdc/v1/pickups', headers:, params:) }

    context 'when the pickup was missed' do
      let(:lookup_type) { 'PickupConfirmationID' }
      let(:lookup_value) do
        create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
        shipment.update!(pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago)
        pickup_request.update!(accepted_pickup_on: 2.days.ago)
        pickup_request.tap(&:miss!).id
      end

      it { expect(json).to(include('status' => 'Rescheduled')) }

      it do
        expect(json['informationCode']).to(include('subCode' => 'missed', 'subCodeDescription' => 'Driver dispatched but did not pick up'))
      end
    end

    context 'with a pickup confirmation ID' do
      let(:lookup_type) { 'PickupConfirmationID' }
      let(:lookup_value) { pickup_request.id }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json).to(include('pickupConfirmationId' => pickup_request.id.to_s, 'status' => 'Accepted')) }
      it { expect(json['shipmentArray'].sole).to(include('proNumber' => shipment.load_id.to_s)) }
    end

    context 'with a PRO number' do
      let(:lookup_type) { 'PRO' }
      let(:lookup_value) { pickup_request.shipments.sole.load_id }

      it { expect(json).to(include('pickupConfirmationId' => pickup_request.id.to_s)) }
    end

    context 'with a PRO number without a pickup request' do
      let(:lookup_type) { 'PRO' }
      let(:lookup_value) { shipment.load_id }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'with an unknown lookup type' do
      let(:lookup_type) { 'BOL' }
      let(:lookup_value) { '1' }

      it { expect(response).to(have_http_status(:bad_request)) }
    end
  end

  describe 'POST /api/dsdc/v1/pickups' do
    context 'when the close time is before the ready time' do
      before do
        body['closeTime'] = '2026-11-02T08:00:00-08:00'
        post('/api/dsdc/v1/pickups', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:bad_request)) }
    end

    context 'when the close time is not ISO 8601' do
      before do
        body['closeTime'] = '4:30 PM'
        post('/api/dsdc/v1/pickups', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:bad_request)) }
    end

    context 'when the PRO number is unknown' do
      before do
        body['shipmentDetails'][0]['proNumber'] = '0'
        post('/api/dsdc/v1/pickups', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:bad_request)) }
      it { expect(json['message']).to(include('0')) }
    end

    context 'when the request is a test' do
      before do
        body['isTest'] = 'True'
        post('/api/dsdc/v1/pickups', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(shipment.reload.pickup_hours_end_at).to(eq('17:00')) }
      it { expect(shipment.reload.pickup_request).to(be_nil) }
    end

    context 'when the shipment belongs to another pickup request' do
      before do
        pickup_request
        post('/api/dsdc/v1/pickups', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:bad_request)) }
    end

    context 'when the shipment was picked up' do
      let(:shipment) { create(:shipment, :usd, broker_customer: api_key.authorizable.companyable) }

      before { post('/api/dsdc/v1/pickups', headers:, params: body.to_json) }

      it { expect(response).to(have_http_status(:bad_request)) }
    end

    context 'with a valid request' do
      before { post('/api/dsdc/v1/pickups', headers:, params: body.to_json) }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json.sole).to(include('carrierPickupNumber' => shipment.reload.pickup_request_id.to_s, 'pickupStatus' => 'Accepted')) }

      it do
        expect(shipment.reload).to(have_attributes(pickup_hours_end_at: '4:30 PM', pickup_hours_start_at: '9:00 AM',
                                                   pickup_on: Date.new(2026, 11, 2)))
      end

      it { expect(shipment.reload.pickup_request.created_by).to(eq(api_key.authorizable)) }
      it { expect(PickupRequest.count).to(eq(1)) }
    end
  end

  describe 'PUT /api/dsdc/v1/pickups/:pickup_id' do
    let(:other_shipment) { create(:shipment, :usd, broker_customer: api_key.authorizable.companyable, pickup_request:) }

    before do
      other_shipment
      body['closeTime'] = '2026-11-02T17:00:00-08:00'
      put("/api/dsdc/v1/pickups/#{pickup_request.id}", headers:, params: body.to_json)
    end

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(shipment.reload.pickup_hours_end_at).to(eq('5:00 PM')) }
    it { expect(other_shipment.reload.pickup_request).to(be_nil) }
  end
end
