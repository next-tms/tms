require 'rails_helper'

RSpec.describe('APIKeys') do
  let(:api_key) { create(:api_key, authorizable: user) }
  let(:user) { create(:customer_user) }

  before do
    seed_settings
    sign_in(user)
  end

  describe 'GET /account/api-keys' do
    before do
      api_key
      get('/account/api-keys')
    end

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(response.body).to(include(api_key.name, "tms_…#{api_key.token_suffix}")) }
    it { expect(response.body).not_to(include(api_key.token)) }

    context 'when the request repeats the ETag' do
      before { get('/account/api-keys', headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { expect(response).to(have_http_status(:not_modified)) }
    end
  end

  describe 'GET /account/api-keys/active' do
    let(:expired_api_key) { create(:api_key, expires_at: 1.minute.ago, authorizable: user) }

    before do
      api_key
      expired_api_key
      get('/account/api-keys/active')
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(api_key.name)) }
    it { expect(response.body).not_to(include(expired_api_key.name)) }
  end

  describe 'GET /account/api-keys/expired' do
    let(:expired_api_key) { create(:api_key, expires_at: 1.minute.ago, authorizable: user) }

    before do
      api_key
      expired_api_key
      get('/account/api-keys/expired')
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(expired_api_key.name)) }
    it { expect(response.body).not_to(include(api_key.name)) }
  end

  describe 'GET /account/api-keys/new' do
    before { get('/account/api-keys/new') }

    it { expect(response).to(have_http_status(:ok)) }
  end

  describe 'POST /account/api-keys' do
    before { post('/account/api-keys', params: { api_key: { name: 'Warehouse WMS', ttl: ttl.iso8601 } }) }

    context 'with a valid TTL' do
      let(:ttl) { 30.days }

      it { expect(response).to(redirect_to("/account/api-keys/#{user.api_keys.sole.id}")) }
      it { expect(user.api_keys.sole).to(have_attributes(name: 'Warehouse WMS', ttl: 30.days)) }
    end

    context 'with a TTL above the maximum' do
      let(:ttl) { 181.days }

      it { expect(response).to(have_http_status(:unprocessable_content)) }
      it { expect(APIKey.where(authorizable: user)).to(be_empty) }
    end
  end

  describe 'GET /account/api-keys/:id' do
    before { get("/account/api-keys/#{api_key.id}") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(api_key.name, api_key.token)) }

    context 'when the key belongs to another user' do
      let(:api_key) { create(:api_key) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'DELETE /account/api-keys/:id' do
    before { delete("/account/api-keys/#{api_key.id}") }

    it { expect(response).to(redirect_to('/account/api-keys')) }
    it { expect(APIKey).not_to(exist(api_key.id)) }

    context 'when the key belongs to another user' do
      let(:api_key) { create(:api_key) }

      it { expect(response).to(have_http_status(:not_found)) }
    end
  end

  describe 'POST /account/api-keys/:api_key_id/roll' do
    before { post("/account/api-keys/#{api_key.id}/roll") }

    it { expect(response).to(redirect_to("/account/api-keys/#{api_key.reload.rolled_to.id}")) }
    it { expect(api_key.reload.expires_at).to(be_within(1.minute).of(APIKey::ROLL_GRACE_PERIOD.from_now)) }

    context 'when the key expired' do
      let(:api_key) { create(:api_key, expires_at: 1.minute.ago, authorizable: user) }

      it { expect(response).to(have_http_status(:not_found)) }
    end
  end
end
