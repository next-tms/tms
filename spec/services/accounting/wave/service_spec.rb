require 'rails_helper'

RSpec.describe Accounting::Wave::Service do
  subject(:service) { integration.service }

  let(:integration) { build(:integration, :wave, credentials:) }
  let(:credentials) { {} }
  let(:redirect_uri) { 'https://app.example.com/oauth-callback' }

  describe '#authorize_url' do
    subject(:url) { service.authorize_url(redirect_uri:, state: 'nonce') }

    let(:query) { Rack::Utils.parse_query(URI(url).query) }

    it { is_expected.to start_with('https://api.waveapps.com/oauth2/authorize/') }
    it { expect(query).to include('redirect_uri' => redirect_uri, 'response_type' => 'code', 'scope' => described_class::SCOPE, 'state' => 'nonce') }
  end

  describe '#connect!' do
    subject(:connect) { service.connect!(code: 'auth-code', realm_id: nil, redirect_uri:) }

    let(:integration) { create(:integration, :wave) }

    before do
      stub_request(:post, 'https://api.waveapps.com/oauth2/token/')
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { access_token: 'access', refresh_token: 'refresh', token_type: 'bearer' }.to_json)

      stub_wave('businesses')

      connect
    end

    it { expect(integration.reload.credentials.symbolize_keys).to include(access_token: 'access', business_id: 'business-1', refresh_token: 'refresh') }
    it { expect(WebMock).to have_requested(:post, described_class::GRAPHQL_URL).with(headers: { 'Authorization' => 'Bearer access' }) }
  end

  describe '#connect_with_token!' do
    subject(:connect) { service.connect_with_token!(access_token: 'full-access') }

    let(:integration) { create(:integration, :wave) }

    before do
      stub_wave('businesses')

      connect
    end

    it { expect(integration.reload.credentials.symbolize_keys).to eq(access_token: 'full-access', business_id: 'business-1') }
    it { expect(WebMock).to have_requested(:post, described_class::GRAPHQL_URL).with(headers: { 'Authorization' => 'Bearer full-access' }) }
  end

  describe '#connected?' do
    context 'with an access token' do
      let(:credentials) { { access_token: 'access' } }

      it { is_expected.to be_connected }
    end

    context 'without an access token' do
      it { is_expected.not_to be_connected }
    end
  end

  describe '#validate_credentials' do
    let(:credentials) { { access_token: 'access' } }

    before { integration.validate }

    it { expect(integration.errors[:credentials]).to include('is missing business_id') }
  end
end
