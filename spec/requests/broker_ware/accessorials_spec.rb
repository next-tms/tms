require 'rails_helper'

RSpec.describe('BrokerWare accessorials') do
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  before do
    create(:accessorial, code: 'DRES', name: 'Residential', transponder_code: 'residential_delivery')
    create(:accessorial, code: 'DREW', name: 'Reweigh')
    create(:accessorial, broker_only: true, code: 'IZZY', name: 'Commission')
    create(:accessorial, broker_customer: create(:broker_customer), name: 'Other Customer')
    get('/api/v1/accessorial', headers:)
  end

  describe 'GET /api/v1/accessorial' do
    it { is_expected.to(have_http_status(:ok)) }

    it { expect(json).to(include({ code: 'DREW', description: 'Reweigh' })) }
    it { expect(json).to(include({ code: 'LGDE', description: 'Liftgate Delivery' })) }
    it { expect(json).to(include({ code: 'RSDE', description: 'Residential' })) }

    it { expect(json.pluck(:description)).not_to(include('Commission', 'Other Customer', 'Residential Delivery')) }

    context 'when the request repeats the ETag' do
      before { get('/api/v1/accessorial', headers: headers.merge('If-None-Match' => response.headers['ETag'])) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end
  end
end
