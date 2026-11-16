require 'rails_helper'

RSpec.describe('BrokerWare tokens') do
  let(:api_key) { create(:api_key) }
  let(:headers) { {} }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:params) { { client_id: api_key.client_id, client_secret: api_key.token, grant_type: 'client_credentials' } }

  before { post('/connect/token', headers:, params:) }

  describe 'POST /connect/token' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.keys).to(eq(%i[access_token expires_in token_type])) }
    it { expect(json[:expires_in]).to(eq(APIKey::ACCESS_TOKEN_TTL.to_i)) }
    it { expect(json[:token_type]).to(eq('Bearer')) }
    it { expect(APIKey.find_signed(json[:access_token], purpose: :access_token)).to(eq(api_key)) }
    it { expect(response.headers['Cache-Control']).to(eq('no-store')) }
    it { expect(api_key.reload.last_used_at).to(be_present) }

    context 'with HTTP Basic client credentials' do
      let(:headers) { { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(api_key.client_id, api_key.token) } }
      let(:params) { { grant_type: 'client_credentials' } }

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when the key expires within a day' do
      let(:api_key) { create(:api_key, expires_at: 1.hour.from_now) }

      it { expect(json[:expires_in]).to(be_within(60).of(1.hour.to_i)) }
    end

    context 'with an expired key' do
      let(:api_key) { create(:api_key, expires_at: 1.minute.ago) }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json).to(eq(error: 'invalid_client')) }
    end

    context 'with a carrier key' do
      let(:api_key) { create(:api_key, :carrier) }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'with a deactivated user' do
      let(:api_key) { create(:api_key, user: create(:customer_user, deactivated: true)) }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'with another key’s client ID' do
      let(:params) { super().merge(client_id: create(:api_key).client_id) }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json).to(eq(error: 'invalid_client')) }
    end

    context 'with an unsupported grant type' do
      let(:params) { super().merge(grant_type: 'password') }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(error: 'unsupported_grant_type')) }
    end

    context 'without a client secret' do
      let(:params) { super().except(:client_secret) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(error: 'invalid_request')) }
    end
  end
end
