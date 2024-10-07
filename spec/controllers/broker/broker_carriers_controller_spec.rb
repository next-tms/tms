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

  describe 'GET #terminals' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:filter) { 'texas' }

    let!(:austin) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier: broker_carrier.carrier) }
    let!(:fremont) { Terminal.create!(address: create(:address, city: 'Fremont', region_iso31662: 'US-CA'), carrier: broker_carrier.carrier) }

    before { get(:terminals, params: { id: broker_carrier.id, q: { described_class::TERMINALS_FILTER => filter } }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:terminals)).to(contain_exactly(austin)) }

    context 'when the filter matches the address text' do
      let(:filter) { 'fremont' }

      it { expect(assigns(:terminals)).to(contain_exactly(fremont)) }
    end

    context 'when the filter matches a region code' do
      let(:filter) { 'US-CA' }

      it { expect(assigns(:terminals)).to(contain_exactly(fremont)) }
    end

    context 'when the filter is blank' do
      let(:filter) { '' }

      it { expect(assigns(:terminals)).to(contain_exactly(austin, fremont)) }
    end
  end

  describe 'GET #search_terminals' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:state) { 'texas' }

    let!(:terminal) do
      Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier: broker_carrier.carrier)
    end

    before do
      Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-CA'), carrier: broker_carrier.carrier)

      get(:search_terminals, params: { city: 'austin', id: broker_carrier.id, state: })
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:terminals)).to(contain_exactly(terminal)) }

    context 'when the state is an abbreviation' do
      let(:state) { 'tx' }

      it { expect(assigns(:terminals)).to(contain_exactly(terminal)) }
    end

    context 'when the state is blank' do
      let(:state) { nil }

      it { expect(assigns(:terminals)).to(be_empty) }
    end
  end

  describe 'PATCH #update' do
    let(:ach_attributes) do
      { encrypted_ach_account_number: '1234', encrypted_ach_bank_name: 'First Bank', encrypted_ach_routing_number: '123456789' }
    end
    let(:broker_carrier) { create(:broker_carrier) }

    before { patch(:update, params: { broker_carrier: ach_attributes, id: broker_carrier.id }) }

    it { is_expected.to(redirect_to([ :broker, broker_carrier ])) }
    it { expect(broker_carrier.reload).to(have_attributes(ach_attributes)) }
  end


  describe 'GET #index' do
    let(:broker_carrier) { create(:broker_carrier, broker: current_user.broker) }

    before do
      broker_carrier
      get(:index, format:)
    end

    context 'when CSV' do
      let(:format) { :csv }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('text/csv')) }
      it { expect(response.body).to(include(broker_carrier.name)) }
      it { expect(response.body).not_to(include(BrokerCarrier.human_attribute_name(:password))) }
    end

    context 'when YAML' do
      let(:format) { :yaml }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('application/x-yaml')) }
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
