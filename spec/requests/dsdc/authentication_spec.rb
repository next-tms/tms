require 'rails_helper'

RSpec.describe('DSDC authentication') do
  let(:api_key) { create(:api_key) }
  let(:json) { response.parsed_body }
  let(:path) { "/api/dsdc/shipment/pro/#{shipment.load_id}/verified" }
  let(:shipment) { create(:shipment, broker_customer: api_key.authorizable.companyable) }

  context 'with a Bearer token' do
    before { get(path, headers: { 'Authorization' => "Bearer #{api_key.token}" }) }

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(api_key.reload.last_used_at).to(be_present) }
  end

  context 'with an expired key' do
    let(:api_key) { create(:api_key, expires_at: 1.minute.ago) }

    before { get(path, headers: { 'X-API-Key' => api_key.token }) }

    it { expect(response).to(have_http_status(:unauthorized)) }
    it { expect(json['message']).to(include(api_key.name, 'expired')) }
    it { expect(response.headers['WWW-Authenticate']).to(eq('Bearer realm="DSDC"')) }
  end

  context 'with an unknown key' do
    before { get(path, headers: { 'X-API-Key' => 'tms_unknown' }) }

    it { expect(json['message']).to(eq(I18n.t('api_keys.errors.invalid'))) }
  end

  context 'when the user is deactivated' do
    let(:api_key) { create(:api_key, authorizable: create(:customer_user, deactivated: true)) }

    before { get(path, headers: { 'X-API-Key' => api_key.token }) }

    it { expect(response).to(have_http_status(:unauthorized)) }
  end

  context 'with a broker carrier key' do
    let(:api_key) { create(:api_key, :broker_carrier) }
    let(:shipment) { create(:shipment) }

    before { get(path, headers: { 'X-API-Key' => api_key.token }) }

    it { expect(response).to(have_http_status(:not_found)) }
  end

  context 'with a public endpoint' do
    before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/public") }

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(response.headers['Cache-Control']).to(include('public')) }
  end

  describe 'rate limiting' do
    let(:cache_store) { DSDC::ApplicationController.cache_store }

    before { allow(cache_store).to(receive(:increment).and_call_original) }

    context 'when the key exceeds the limit' do
      before do
        allow(cache_store).to(receive(:increment).and_return(301))
        get(path, headers: { 'X-API-Key' => api_key.token })
      end

      it { expect(response).to(have_http_status(:too_many_requests)) }
      it { expect(response.headers['Retry-After']).to(eq('60')) }
      it { expect(json['message']).to(eq(I18n.t('dsdc.errors.rate_limited'))) }
    end

    context 'with an unverified key on a public endpoint' do
      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/public", headers: { 'X-API-Key' => 'tms_unknown' }) }

      it { expect(cache_store).to(have_received(:increment).with(end_with(':127.0.0.1'), any_args)) }
    end

    context 'with a verified key' do
      before { get(path, headers: { 'X-API-Key' => api_key.token }) }

      it { expect(cache_store).to(have_received(:increment).with(end_with(":#{api_key.token_digest}"), any_args)) }
    end
  end
end
