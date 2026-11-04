require 'rails_helper'

RSpec.describe('Broker::Carriers::Accountings') do
  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    allow(Accounting).to(receive(:record_class).with(:vendor).and_return(double(order: [])))
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/accounting' do
    let!(:alpha) { create(:broker_carrier, carrier: create(:carrier, name: 'Alpha')) }
    let!(:zulu) { create(:broker_carrier, carrier: create(:carrier, name: 'Zulu')) }

    before { get('/broker/carriers/accounting') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carriers)).to(eq([alpha, zulu])) }
    it { expect(assigns(:vendors)).to(eq([])) }

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when a customer user' do
      let(:current_user) { create(:customer_user).tap { |customer| customer.contact.contact_roles.create!(role: :root) } }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when impersonating a customer' do
      before do
        post("/broker/users/#{create(:customer_user).id}/impersonate")
        get('/broker/carriers/accounting')
      end

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PATCH /broker/carriers/accounting' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:params) { { accounting: { broker_carriers: { broker_carrier.id => { accounting_vendor_id: '42' } } } } }

    before { patch('/broker/carriers/accounting', params:) }

    it { is_expected.to(redirect_to('/broker/carriers/accounting')) }
    it { expect(broker_carrier.reload.accounting_vendor_id).to(eq(42)) }
    it { expect(flash[:success]).to(eq('Accounting vendors updated')) }
  end
end
