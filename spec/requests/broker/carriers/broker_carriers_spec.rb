require 'rails_helper'

RSpec.describe('Broker::Carriers::BrokerCarriers') do
  let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:check_mailing_address) { nil }
  let(:path) { "/broker/carriers/#{carrier.id}/accounts" }

  before do
    seed_settings
    create(:setting, key: 'mailing_address', value: create(:address))
    sign_in(create(:root_broker_user))
  end

  describe 'GET /broker/carriers/:carrier_id/accounts' do
    let(:customer_name) { other_broker_carrier.broker_customer.customer.name }
    let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

    before do
      broker_carrier
      other_broker_carrier
      get(path)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carriers)).to(contain_exactly(broker_carrier, other_broker_carrier)) }
    it { expect(response.body).to(include(ERB::Util.html_escape(customer_name), "#{path}/#{broker_carrier.id}")) }
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:id' do
    before { get("#{path}/#{broker_carrier.id}") }

    it { is_expected.to(have_http_status(:ok)) }

    context 'with an account of another carrier' do
      before { get("#{path}/#{create(:broker_carrier).id}") }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/new' do
    before do
      broker_carrier
      get("#{path}/new")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carrier)).to(have_attributes(carrier:, new_record?: true)) }
    it { expect(assigns(:broker_carrier).check_mailing_address).to(be_a_new(Address)) }
    it { expect(response.body).not_to(include('broker_carrier[carrier_id]')) }
  end

  describe 'POST /broker/carriers/:carrier_id/accounts' do
    let(:created) { carrier.broker_carriers.find_by(account: '42') }

    before do
      broker_carrier
      post(path, params: { broker_carrier: { account: '42', carrier_id: create(:carrier).id } })
    end

    it { is_expected.to(redirect_to("#{path}/#{created.id}")) }
    it { expect(created.carrier).to(eq(carrier)) }
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:id/edit' do
    before { get("#{path}/#{broker_carrier.id}/edit") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carrier).check_mailing_address).to(be_a_new(Address)) }

    context 'when Transponder has a check mailing address' do
      let(:carrier) { create(:carrier, :saia) }

      it { expect(assigns(:broker_carrier).check_mailing_address).to(have_attributes(city: 'Dallas', new_record?: true)) }
    end

    context 'when the account has a check mailing address' do
      let(:check_mailing_address) { create(:address) }

      it { expect(assigns(:broker_carrier).check_mailing_address).to(eq(check_mailing_address)) }
    end
  end

  describe 'PATCH /broker/carriers/:carrier_id/accounts/:id' do
    let(:ach_attributes) do
      { encrypted_ach_account_number: '1234', encrypted_ach_bank_name: 'First Bank', encrypted_ach_routing_number: '123456789' }
    end

    before { patch("#{path}/#{broker_carrier.id}", params: { broker_carrier: ach_attributes }) }

    it { is_expected.to(redirect_to("#{path}/#{broker_carrier.id}")) }
    it { expect(broker_carrier.reload).to(have_attributes(ach_attributes)) }
  end
end
