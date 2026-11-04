require 'rails_helper'

RSpec.describe('Broker::Carriers::BrokerCarriers::PaymentTransactions') do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:current_user) { create(:root_broker_user) }
  let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
  let!(:payment_transaction) { create(:payment_transaction, broker_carrier:, shipment: create(:shipment, :usd)) }

  before do
    seed_settings
    create(:payment_transaction, broker_carrier: other_account, shipment: create(:shipment, :usd))
    sign_in(current_user)
    get("/broker/carriers/#{broker_carrier.carrier_id}/accounts/#{broker_carrier.id}/bills")
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:broker_carrier_id/bills' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:payment_transactions)).to(contain_exactly(payment_transaction)) }
    it { expect(assigns(:payment_transactions).first.association(:shipment)).to(be_loaded) }

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
