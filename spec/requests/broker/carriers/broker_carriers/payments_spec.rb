require 'rails_helper'

RSpec.describe('Broker::Carriers::BrokerCarriers::Payments') do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:current_user) { create(:root_broker_user) }
  let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
  let!(:payment) { create(:payment, broker_carrier:) }

  before do
    seed_settings
    create(:payment, broker_carrier: other_account)
    sign_in(current_user)
    get("/broker/carriers/#{broker_carrier.carrier_id}/accounts/#{broker_carrier.id}/payments")
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:broker_carrier_id/payments' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:payments)).to(contain_exactly(payment)) }
    it { expect(assigns(:payments).first.association(:broker_carrier)).to(be_loaded) }

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
