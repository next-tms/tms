require 'rails_helper'

RSpec.describe('Freightview::Shipments') do
  let(:api_key) { create(:api_key) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.token}" } }
  let(:json) { Freightview.decode_keys(response.parsed_body) }
  let(:origin) { json[:locations].find { |location| location[:type] == 'origin' } }
  let(:shipment) do
    create(
      :shipment,
      bol: '1001',
      broker_customer: api_key.user.companyable,
      customer_reference: '2002',
      delivered_at: nil,
      out_for_delivery_at: nil
    )
  end

  describe 'GET /api/v2.0/shipments/:shipment_id' do
    context 'when the shipment belongs to the API key user' do
      before { get("/api/v2.0/shipments/#{shipment.load_id}", headers:) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(json).to(include(shipment_id: shipment.load_id.to_s, status: 'picked-up')) }
      it { expect(json[:bol]).to(include(bol_number: '1001')) }
      it { expect(json[:ref_nums]).to(include(type: 'other', value: '2002')) }
      it { expect(json[:tracking]).to(include(status: 'in-transit', tracking_number: shipment.load_id.to_s)) }
      it { expect(json[:locations].pluck(:type)).to(eq(['origin', 'destination'])) }
      it { expect(origin).to(include(city: shipment.shipper_address.city, sequence: 0, stop_type: 'pickup')) }
      it { expect(json).not_to(have_key(:quotes)) }
      it { expect(response.headers['ETag']).to(be_present) }
    end

    context 'when the shipment belongs to another customer' do
      let(:shipment) { create(:shipment) }

      before { get("/api/v2.0/shipments/#{shipment.load_id}", headers:) }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(json).to(include(name: 'NotFoundError', request_id: be_present)) }
    end

    context 'when the shipment does not exist' do
      before { get('/api/v2.0/shipments/0', headers:) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
