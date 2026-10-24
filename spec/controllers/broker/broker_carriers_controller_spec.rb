require 'rails_helper'

RSpec.describe(Broker::BrokerCarriersController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before do
    sign_in(current_user)
    allow(Accounting).to(receive(:record_class).with(:vendor).and_return(double(order: [])))
  end

  describe 'GET #accounting' do
    before { get(:accounting) }

    context 'when accounts payable' do
      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:vendors)).to(eq([])) }
    end

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when a customer user' do
      let(:current_user) { create(:customer_user).tap { |customer| customer.contact.contact_roles.create!(role: :root) } }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PATCH #update_accounting' do
    let(:broker_carrier) { create(:broker_carrier) }

    before do
      patch(:update_accounting, params: { accounting: { broker_carriers: { broker_carrier.id => { accounting_vendor_id: '42' } } } })
    end

    it { is_expected.to(redirect_to(accounting_broker_broker_carriers_path)) }
    it { expect(broker_carrier.reload.accounting_vendor_id).to(eq(42)) }
    it { expect(flash[:success]).to(eq('Accounting vendors updated')) }
  end
end
