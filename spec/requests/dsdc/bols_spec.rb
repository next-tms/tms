require 'rails_helper'

RSpec.describe('DSDC::BOLs') do
  let(:api_key) { create(:api_key) }
  let(:body) { JSON.parse(file_fixture('dsdc/bol_request.json').read) }
  let(:headers) { { 'Content-Type' => 'application/json', 'X-API-Key' => api_key.token } }
  let(:json) { response.parsed_body }
  let(:shipment) { Shipment.find_by(load_id: json.dig('referenceNumbers', 'pro')) }

  before do
    create(:accessorial, freight_kit_code: 'liftgate_delivery', name: 'Lift gate delivery')
    create(:broker_user).contact.add_role(:dispatch)
    create(:packaging, freight_kit_type: 'pallet')
  end

  describe 'DELETE /api/dsdc/bol/v1/app/:pro' do
    let(:existing) { create(:shipment, :usd, broker_customer: api_key.user.companyable, picked_up_at:) }

    before { delete("/api/dsdc/bol/v1/app/#{existing.load_id}", headers:) }

    context 'when the shipment is not picked up' do
      let(:picked_up_at) { nil }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(existing.reload.canceled_at).to(be_present) }
    end

    context 'when the shipment is picked up' do
      let(:picked_up_at) { 1.day.ago }

      it { expect(response).to(have_http_status(:bad_request)) }
      it { expect(existing.reload.canceled_at).to(be_nil) }
    end
  end

  describe 'POST /api/dsdc/bol/v1/app' do
    context 'when the API key belongs to a broker user' do
      let(:api_key) { create(:api_key, user: broker_user) }
      let(:body) { super().deep_merge('billTo' => { 'account' => broker_customer.id.to_s }) }
      let(:broker_customer) { create(:broker_customer) }
      let(:broker_user) { create(:broker_user).tap { |user| user.contact.add_role(:dispatch) } }

      before { post('/api/dsdc/bol/v1/app', headers:, params: body.to_json) }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(shipment).to(have_attributes(broker_customer:, created_by: broker_user)) }

      context 'when billTo.account does not match a customer' do
        let(:body) { super().deep_merge('billTo' => { 'account' => '0' }) }

        it { expect(response).to(have_http_status(:bad_request)) }
        it { expect(json.first).to(include('code' => '300')) }
        it { expect(Shipment.count).to(eq(0)) }
      end

      context 'when the broker user cannot book for the customer' do
        let(:broker_user) { create(:broker_user) }

        it { expect(response).to(have_http_status(:bad_request)) }
        it { expect(Shipment.count).to(eq(0)) }
      end
    end

    context 'when the BOL image cannot be created' do
      before do
        allow(PDFService::Renderer).to(receive(:call).and_raise(StandardError))
        allow(Rails.env).to(receive(:production?).and_return(true))
        allow(Sentry).to(receive(:capture_exception))
        body['images']['includeBol'] = true
        post('/api/dsdc/bol/v1/app', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json.dig('messageStatus', 'information').pluck('code')).to(include('1200')) }
      it { expect(Sentry).to(have_received(:capture_exception).with(StandardError)) }
    end

    context 'when the BOL image cannot be created outside production' do
      before do
        allow(PDFService::Renderer).to(receive(:call).and_raise(StandardError))
        body['images']['includeBol'] = true
      end

      it { expect { post('/api/dsdc/bol/v1/app', headers:, params: body.to_json) }.to(raise_error(StandardError)) }
    end

    context 'when the request includes the BOL image' do
      before do
        allow(PDFService::Renderer).to(receive(:call).and_return('%PDF-1.7'))
        body['images']['includeBol'] = true
        post('/api/dsdc/bol/v1/app', headers:, params: body.to_json)
      end

      it { expect(json.dig('images', 'bol')).to(eq(Base64.strict_encode64('%PDF-1.7'))) }
      it { expect(json.dig('images', 'shippingLabels')).to(be_nil) }
    end

    context 'when the request includes the shipping labels' do
      before do
        body['images']['includeShippingLabels'] = true
        post('/api/dsdc/bol/v1/app', headers:, params: body.to_json)
      end

      it { expect(Base64.strict_decode64(json.dig('images', 'shippingLabels'))).to(start_with('%PDF')) }
    end

    context 'when the request is a test' do
      before do
        body['bol']['isTest'] = true
        post('/api/dsdc/bol/v1/app', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json.dig('referenceNumbers', 'pro')).to(be_nil) }
      it { expect(Shipment.count).to(eq(0)) }
    end

    context 'when the request is invalid' do
      before do
        body['commodities']['handlingUnits'][0]['count'] = 0
        post('/api/dsdc/bol/v1/app', headers:, params: body.to_json)
      end

      it { expect(response).to(have_http_status(:bad_request)) }
      it { expect(json.first).to(include('code' => '300')) }
    end

    context 'when the request names an existing PRO' do
      let(:existing) { create(:shipment, :usd, broker_customer: api_key.user.companyable, bol: '1001', picked_up_at: nil) }

      before { post("/api/dsdc/bol/v1/app?pro=#{existing.load_id}", headers:, params: body.to_json) }

      it { expect(shipment).not_to(eq(existing)) }
      it { expect(existing.reload.bol).to(eq('1001')) }
    end

    context 'with a valid request' do
      before { post('/api/dsdc/bol/v1/app', headers:, params: body.to_json) }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json['messageStatus']).to(include('status' => 'WARNING')) }
      it { expect(json.dig('messageStatus', 'information', 0, 'message')).to(include('XYZ')) }

      it { expect(shipment).to(have_attributes(bol: '5550001', broker_customer: api_key.user.companyable, customer_reference: '7770001')) }

      it do
        expect(shipment).to(have_attributes(pickup_hours_end_at: '4:30 PM', pickup_hours_start_at: '9:00 AM',
                                            pickup_on: Date.new(2026, 11, 2)))
      end

      it { expect(shipment.items.sole).to(have_attributes(declared_freight_class: 70, nmfc: '123456-02', quantity: 2, weight: 900)) }
      it { expect(shipment.accessorials.pluck(:freight_kit_code)).to(eq(['liftgate_delivery'])) }
      it { expect(shipment.shipper_address).to(have_attributes(country_alpha2: 'US', region_iso31662: 'US-CA', zip_code: '90012')) }
      it { expect(shipment.booked_at).to(be_present) }
    end
  end

  describe 'PUT /api/dsdc/bol/v1/app/:pro' do
    let(:existing) { create(:shipment, :usd, broker_customer: api_key.user.companyable, picked_up_at: nil) }

    before do
      body['bol']['function'] = 'Update'
      body['destination']['name'] = 'Gadget Depot'
      put("/api/dsdc/bol/v1/app/#{existing.load_id}", headers:, params: body.to_json)
    end

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(existing.reload.receiver_name).to(eq('Gadget Depot')) }
    it { expect(existing.reload.items.count).to(eq(1)) }
  end
end
