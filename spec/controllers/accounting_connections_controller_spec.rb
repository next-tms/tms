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
  end
end
