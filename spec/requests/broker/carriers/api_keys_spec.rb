require 'rails_helper'

RSpec.describe('Broker::Carriers::APIKeys') do
  let(:api_key) { create(:api_key, user: carrier_user) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:carrier) { broker_carrier.carrier }
  let(:carrier_user) { create(:carrier_user, companyable: carrier) }
  let(:path) { "/broker/carriers/#{carrier.id}/api-keys" }
  let(:user) { create(:root_broker_user) }

  before do
    seed_settings
    sign_in(user)
  end

  describe 'GET /broker/carriers/:carrier_id/api-keys' do
    let(:other_api_key) { create(:api_key, :carrier) }

    before do
      api_key
      other_api_key
      get(path)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(api_key.name, "tms_…#{api_key.token_suffix}", carrier_user.full_name)) }
    it { expect(response.body).not_to(include(api_key.token, other_api_key.name)) }

    context 'when the request repeats the ETag' do
      before { get(path, headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when the user is not in accounts payable' do
      let(:user) { create(:broker_user) }

      it { expect(response.body).not_to(include(api_key.name)) }
    end
  end

  describe 'GET /broker/carriers/:carrier_id/api-keys/new' do
    before do
      carrier_user
      get("#{path}/new")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(carrier_user.full_name)) }
  end

  describe 'POST /broker/carriers/:carrier_id/api-keys' do
    let(:user_id) { carrier_user.id }

    before { post(path, params: { api_key: { name:, ttl: 30.days.iso8601, user_id: } }) }

    context 'with a name' do
      let(:name) { 'Carrier billing' }

      it { is_expected.to(redirect_to("#{path}/#{carrier.api_keys.sole.id}")) }
      it { expect(carrier.api_keys.sole).to(have_attributes(name: 'Carrier billing', ttl: 30.days, user: carrier_user)) }
    end

    context 'without a name' do
      let(:name) { '' }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
      it { expect(carrier.api_keys).to(be_empty) }
    end

    context 'with a user from another carrier' do
      let(:name) { 'Carrier billing' }
      let(:user_id) { create(:carrier_user).id }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(APIKey).not_to(exist) }
    end
  end

  describe 'GET /broker/carriers/:carrier_id/api-keys/:id' do
    before { get("#{path}/#{api_key.id}") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include(api_key.name, api_key.token)) }

    context 'when the key belongs to another carrier' do
      let(:api_key) { create(:api_key, :carrier) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when the key belongs to a customer user' do
      let(:api_key) { create(:api_key) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'DELETE /broker/carriers/:carrier_id/api-keys/:id' do
    before { delete("#{path}/#{api_key.id}") }

    it { is_expected.to(redirect_to(path)) }
    it { expect(APIKey).not_to(exist(api_key.id)) }
  end

  describe 'POST /broker/carriers/:carrier_id/api-keys/:api_key_id/roll' do
    before { post("#{path}/#{api_key.id}/roll") }

    it { is_expected.to(redirect_to("#{path}/#{api_key.reload.rolled_to.id}")) }
    it { expect(api_key.reload.expires_at).to(be_within(1.minute).of(APIKey::ROLL_GRACE_PERIOD.from_now)) }
    it { expect(api_key.reload.rolled_to.user).to(eq(carrier_user)) }

    context 'when the key expired' do
      let(:api_key) { create(:api_key, expires_at: 1.minute.ago, user: carrier_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
