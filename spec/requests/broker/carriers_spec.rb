require 'rails_helper'

RSpec.describe('Broker::Carriers') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    create(:setting, key: 'mailing_address', value: create(:address))
    sign_in(current_user)
  end

  describe 'GET /broker/carriers' do
    before do
      broker_carrier
      create(:carrier, name: 'Unused Freight')
      get('/broker/carriers')
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('Acme Freight')) }
    it { expect(response.body).not_to(include('Unused Freight')) }

    context 'when impersonating a customer' do
      before do
        post("/broker/users/#{create(:customer_user).id}/impersonate")
        get('/broker/carriers')
      end

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /broker/carriers/:id' do
    before { get("/broker/carriers/#{broker_carrier.carrier_id}") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('Acme Freight')) }

    context 'when the carrier has no accounts' do
      before { get("/broker/carriers/#{create(:carrier).id}") }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /broker/carriers/new' do
    before { get('/broker/carriers/new') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('broker_carrier[carrier_id]')) }
  end

  describe 'POST /broker/carriers' do
    let(:created) { BrokerCarrier.find_by(account: '42') }

    before { post('/broker/carriers', params: { broker_carrier: { account: '42', carrier_id: carrier.id } }) }

    it { is_expected.to(redirect_to("/broker/carriers/#{carrier.id}/accounts/#{created.id}")) }
    it { expect(created.carrier).to(eq(carrier)) }
  end
end
