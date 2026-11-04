require 'rails_helper'

RSpec.describe('Broker::Carriers::PaymentTransactions') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }
  let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/bills' do
    let(:current_user) { create(:broker_user).tap { |user| user.contact.contact_roles.create!(role: :accounts_payable) } }

    before do
      create(:payment_transaction, broker_carrier:, shipment: create(:shipment, :usd))
      create(:payment_transaction, broker_carrier: other_broker_carrier, shipment: create(:shipment, :usd))
      create(:payment_transaction, shipment: create(:shipment, :usd))
      get("/broker/carriers/#{broker_carrier.carrier_id}/bills")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:payment_transactions).map(&:broker_carrier)).to(contain_exactly(broker_carrier, other_broker_carrier)) }
    it { expect(assigns(:payment_transactions).first.association(:broker_carrier)).to(be_loaded) }

    context 'when not accounts payable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
