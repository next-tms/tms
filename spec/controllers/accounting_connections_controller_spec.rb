require 'rails_helper'

RSpec.describe(AccountingConnectionsController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }
  let(:params) { { code: 'code', kind: 'quickbooks', realmId: '1', state: 'app.nonce' } }

  before do
    allow(FetchBrokerCarrierAccountingVendorIdsJob).to(receive(:perform_later))
    allow(FetchBrokerCustomerAccountingCustomerIdsJob).to(receive(:perform_later))
    allow_any_instance_of(Accounting::QuickBooks::Service).to(receive(:connect!))
    sign_in(current_user)
    session[:accounting_oauth_nonce] = 'nonce'
  end

  describe 'GET #callback' do
    before { get(:callback, params:) }

    it { is_expected.to(redirect_to(broker_settings_company_accounting_path)) }
    it { expect(flash[:success]).to(be_present) }
    it { expect(FetchBrokerCarrierAccountingVendorIdsJob).to(have_received(:perform_later).with(no_args)) }
    it { expect(FetchBrokerCustomerAccountingCustomerIdsJob).to(have_received(:perform_later).with(no_args)) }

    context 'when the code is missing' do
      let(:params) { { kind: 'quickbooks', realmId: '1', state: 'app.nonce' } }

      it { is_expected.to(redirect_to(broker_settings_company_accounting_path)) }
      it { expect(flash[:error]).to(be_present) }
      it { expect(FetchBrokerCarrierAccountingVendorIdsJob).not_to(have_received(:perform_later)) }
    end

    context 'when the state does not match the session' do
      let(:params) { { code: 'code', kind: 'quickbooks', realmId: '1', state: 'app.other' } }

      it { is_expected.to(redirect_to(broker_settings_company_accounting_path)) }
      it { expect(flash[:error]).to(be_present) }
      it { expect(FetchBrokerCarrierAccountingVendorIdsJob).not_to(have_received(:perform_later)) }
    end

    context 'when the state has no Flight app ID' do
      let(:params) { { code: 'code', kind: 'quickbooks', realmId: '1', state: 'nonce' } }

      it { expect(flash[:success]).to(be_present) }
    end
  end

  describe 'GET #connect' do
    let(:flight_url) { nil }
    let(:query) { Rack::Utils.parse_query(URI.parse(response.location).query) }

    before do
      allow(ENV).to(receive(:fetch).and_call_original)
      allow(ENV).to(receive(:fetch).with('FLIGHT_APP_ID').and_return('app'))
      allow(ENV).to(receive(:fetch).with('FLIGHT_URL', nil).and_return(flight_url))
      get(:connect, params: { kind: 'quickbooks' })
    end

    it { is_expected.to(redirect_to(%r{\Ahttps://appcenter\.intuit\.com/connect/oauth2\?client_id=})) }
    it { expect(query['redirect_uri']).to(eq(oauth_callback_quickbooks_accounting_url)) }
    it { expect(query['state']).to(eq(session[:accounting_oauth_nonce])) }
    it { expect(response.headers['Referrer-Policy']).to(eq('no-referrer')) }

    context 'when Flight is configured' do
      let(:flight_url) { 'https://flight.example.com' }

      it { expect(query['redirect_uri']).to(eq('https://flight.example.com/oauth/callback/intuit')) }
      it { expect(query['state']).to(eq("app.#{session[:accounting_oauth_nonce]}")) }
    end
  end
end
