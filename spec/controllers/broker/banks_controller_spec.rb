require 'rails_helper'

RSpec.describe(Broker::BanksController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before do
    sign_in(current_user)
    allow(Accounting).to(receive(:record_class).with(:account).and_return(double(order: [])))
  end

  describe 'GET #accounting' do
    before { get(:accounting) }

    context 'when root' do
      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:accounts)).to(eq([])) }
    end

    context 'when not root' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when a customer user' do
      let(:current_user) { create(:customer_user).tap { |customer| customer.contact.contact_roles.create!(role: :root) } }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PATCH #update_accounting' do
    let(:bank) { create(:bank) }

    before { patch(:update_accounting, params: { accounting: { banks: { bank.id => { accounting_account_id: '42' } } } }) }

    it { is_expected.to(redirect_to(accounting_broker_banks_path)) }
    it { expect(bank.reload.accounting_account_id).to(eq(42)) }
    it { expect(flash[:success]).to(eq('Accounting accounts updated')) }
  end
end
