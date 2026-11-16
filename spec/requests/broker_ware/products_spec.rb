require 'rails_helper'

RSpec.describe('BrokerWare products') do
  let(:api_key) { create(:api_key) }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  before { get('/api/v1/ProductList', headers: { 'Authorization' => "Bearer #{api_key.access_token}" }) }

  describe 'GET /api/v1/ProductList' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(eq([])) }
  end
end
