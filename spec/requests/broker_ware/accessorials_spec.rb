require 'rails_helper'

RSpec.describe('BrokerWare accessorials') do
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:residential_delivery) { create(:accessorial, code: 'DRES', freight_kit_code: 'residential_delivery', name: 'Residential Delivery') }
  let(:reweigh) { create(:accessorial, code: 'DREW', freight_kit_code: nil, name: 'Reweigh') }

  before do
    residential_delivery
    reweigh
    create(:broker_accessorial, broker_customer: create(:broker_customer), name: 'Other Customer')
    get('/api/v1/accessorial', headers:)
  end

  describe 'GET /api/v1/accessorial' do
    it { is_expected.to(have_http_status(:ok)) }

    it { expect(json).to(include({ code: 'DREW', description: 'Reweigh' })) }
    it { expect(json).to(include({ code: 'RSDE', description: 'Residential Delivery' })) }

    it { expect(json.pluck(:description)).not_to(include('Other Customer')) }

    context 'when the request repeats the ETag' do
      before { get('/api/v1/accessorial', headers: headers.merge('If-None-Match' => response.headers['ETag'])) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end
  end
end
