require 'rails_helper'

RSpec.describe(AccountingConnectionsController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe 'GET #callback' do
    before do
      allow(FetchBrokerCarrierAccountingVendorIdsJob).to(receive(:perform_later))
      allow(FetchBrokerCustomerAccountingCustomerIdsJob).to(receive(:perform_later))
      allow_any_instance_of(Accounting::QuickBooks::Service).to(receive(:connect!))
      session[:accounting_oauth_nonce] = 'nonce'
    end

    context 'when website_homepage is not set' do
      before { get(:callback, params: { code: 'code', kind: 'quickbooks', realmId: '1', state: 'app.nonce' }) }

      it { is_expected.to(redirect_to(root_path)) }
    end

    context 'when website_homepage is set' do
      before do
        create(:setting, key: 'website_homepage', value: 'https://example.com')
        get(:callback, params: { code: 'code', kind: 'quickbooks', realmId: '1', state: 'app.nonce' })
      end

      it { is_expected.to(redirect_to('https://example.com')) }
    end
  end

  describe 'GET #callback jobs' do
    before do
      allow(FetchBrokerCarrierAccountingVendorIdsJob).to(receive(:perform_later))
      allow(FetchBrokerCustomerAccountingCustomerIdsJob).to(receive(:perform_later))
      allow_any_instance_of(Accounting::QuickBooks::Service).to(receive(:connect!)) # rubocop:disable RSpec/AnyInstance
      session[:accounting_oauth_nonce] = 'nonce'
      get(:callback, params: { code: 'code', kind: 'quickbooks', realmId: '1', state: 'app.nonce' })
    end

    it { expect(FetchBrokerCarrierAccountingVendorIdsJob).to(have_received(:perform_later).with(no_args)) }
    it { expect(FetchBrokerCustomerAccountingCustomerIdsJob).to(have_received(:perform_later).with(no_args)) }
  end
end
