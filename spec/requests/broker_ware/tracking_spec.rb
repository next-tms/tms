require 'rails_helper'

RSpec.describe('BrokerWare tracking') do
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:query) { { loadid: shipment.load_id } }
  let(:shipment) do
    create(
      :shipment,
      :usd,
      broker_carrier: create(:broker_carrier, carrier: create(:carrier, name: 'AAA Cooper Transportation', scac: 'AACT')),
      broker_customer:,
      carrier_charge_cents: 50_000,
      shipper_address: create(:address, city: 'Austin', region_iso31662: 'US-TX', zip_code: '78701'),
      tracking_carrier_pro: 'PRO-123',
      truckload: false
    )
  end

  before { get('/api/v1/tracking', headers:, params: query) }

  describe 'GET /api/v1/tracking' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.sole).to(include(carrierName: 'AAA Cooper Transportation', carrierScac: 'AACT')) }
    it { expect(json.sole[:loadId]).to(eq(shipment.load_id)) }
    it { expect(json.sole).to(include(billed: 500.0, mode: 'LTL', poReference: shipment.customer_reference)) }
    it { expect(json.sole).to(include(shipperCity: 'Austin', shipperState: 'TX', shipperZip: '78701')) }
    it { expect(json.sole).to(include(status: 'Delivered', statusDescription: 'Delivered')) }
    it { expect(response.body).not_to(include('PRO-123')) }

    context 'with a camel-cased load ID' do
      let(:query) { { loadId: shipment.load_id } }

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'without a load ID' do
      let(:query) { {} }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'when the shipment belongs to another customer' do
      let(:shipment) { create(:shipment) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
