require 'rails_helper'

RSpec.describe('Broker::Carriers::Payments') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }
  let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/payments' do
    let!(:other_account_payment) { create(:payment, broker_carrier: other_broker_carrier) }
    let!(:payment) { create(:payment, broker_carrier:) }

    before do
      create(:payment)
      get("/broker/carriers/#{broker_carrier.carrier_id}/payments")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:payments)).to(contain_exactly(other_account_payment, payment)) }
    it { expect(assigns(:payments).first.association(:broker_carrier)).to(be_loaded) }

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
