require 'rails_helper'

RSpec.describe('Broker::Carriers::Shipments') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }
  let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/shipments' do
    let!(:shipment) { create(:shipment, broker_carrier:) }
    let!(:other_shipment) { create(:shipment, broker_carrier: other_broker_carrier) }

    before do
      create(:shipment)
      get("/broker/carriers/#{broker_carrier.carrier_id}/shipments")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:shipments)).to(contain_exactly(shipment, other_shipment)) }
    it { expect(assigns(:shipments).first.association(:broker_carrier)).to(be_loaded) }

    context 'when impersonating a customer' do
      before do
        post("/broker/users/#{create(:customer_user).id}/impersonate")
        get("/broker/carriers/#{broker_carrier.carrier_id}/shipments")
      end

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
