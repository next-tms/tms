require 'rails_helper'

RSpec.describe('Broker::Carriers::BrokerCarriers::Shipments') do
  let(:broker_carrier) { create(:broker_carrier) }
  let!(:shipment) { create(:shipment, broker_carrier:) }

  before do
    seed_settings
    create(:shipment, broker_carrier: create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier))
    sign_in(create(:root_broker_user))
    get("/broker/carriers/#{broker_carrier.carrier_id}/accounts/#{broker_carrier.id}/shipments")
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:broker_carrier_id/shipments' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:shipments)).to(contain_exactly(shipment)) }
    it { expect(assigns(:shipments).first.association(:broker_carrier)).to(be_loaded) }
  end
end
