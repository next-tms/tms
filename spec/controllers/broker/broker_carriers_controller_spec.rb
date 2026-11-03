require 'rails_helper'

RSpec.describe(Broker::BrokerCarriersController) do
  let(:current_user) { create(:root_broker_user) }

  before do
    sign_in(current_user)
    allow(Accounting).to(receive(:record_class).with(:vendor).and_return(double(order: [])))
  end

  describe '#accounting_params' do
    subject { controller.__send__(:accounting_params).to_h }

    let(:attributes) { { '1' => { accounting_vendor_id: '2' } } }

    before { controller.params = { accounting: { broker_carriers: attributes } } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe '#broker_carrier_params' do
    subject { controller.__send__(:broker_carrier_params).to_h }

    let(:attributes) { { account: 'ACME', check_mailing_address_attributes: { city: 'Portland' } } }

    before { controller.params = { broker_carrier: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe '#tariff_params' do
    subject { controller.__send__(:tariff_params).to_h }

    let(:attributes) do
      {
        overlength_rules_attributes: { '0' => { cost: '10' } },
        pricing_rules_attributes: { '0' => { max_pallets: '4' } }
      }
    end

    before { controller.params = { broker_carrier: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
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

  describe 'GET #accounting with broker carriers' do
    let!(:alpha) { create(:broker_carrier, carrier: create(:carrier, name: 'Alpha')) }
    let!(:zulu) { create(:broker_carrier, carrier: create(:carrier, name: 'Zulu')) }

    before { get(:accounting) }

    it { expect(assigns(:broker_carriers)).to(eq([alpha, zulu])) }
  end

  describe 'GET #terminals' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:filter) { 'texas' }

    let!(:austin) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier: broker_carrier.carrier) }
    let!(:fremont) do
      Terminal.create!(address: create(:address, city: 'Fremont', region_iso31662: 'US-CA'), carrier: broker_carrier.carrier)
    end

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

    context 'when Transponder shares a terminal for the carrier' do
      let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }

      it { expect(assigns(:terminals)).to(contain_exactly(terminal, *broker_carrier.carrier.transponder_terminals)) }
    end

    context 'when Transponder shares a terminal in another city' do
      let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }

      before { get(:search_terminals, params: { city: 'dallas', id: broker_carrier.id, state: }) }

      it { expect(assigns(:terminals)).to(be_empty) }
    end
  end

  describe 'GET #new' do
    before { get(:new) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carrier)).to(be_new_record) }
    it { expect(assigns(:broker_carrier).check_mailing_address).to(be_a_new(Address)) }
  end

  describe 'GET #edit' do
    let(:broker_carrier) { create(:broker_carrier, check_mailing_address:) }
    let(:check_mailing_address) { nil }

    before { get(:edit, params: { id: broker_carrier.id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_carrier).check_mailing_address).to(be_a_new(Address)) }

    context 'when Transponder has a check mailing address' do
      let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }

      it { expect(assigns(:broker_carrier).check_mailing_address).to(have_attributes(city: 'Dallas', new_record?: true)) }
    end

    context 'when the broker carrier has a check mailing address' do
      let(:check_mailing_address) { create(:address) }

      it { expect(assigns(:broker_carrier).check_mailing_address).to(eq(check_mailing_address)) }
    end
  end

  describe 'POST #create' do
    let(:broker_carrier) { BrokerCarrier.last }
    let(:carrier) { create(:carrier) }

    before { post(:create, params: { broker_carrier: { account: '42', carrier_id: carrier.id } }) }

    it { is_expected.to(redirect_to([:broker, broker_carrier])) }
    it { expect(broker_carrier).to(have_attributes(account: '42', carrier:)) }
  end

  describe 'PATCH #update' do
    let(:ach_attributes) do
      { encrypted_ach_account_number: '1234', encrypted_ach_bank_name: 'First Bank', encrypted_ach_routing_number: '123456789' }
    end
    let(:broker_carrier) { create(:broker_carrier) }

    before { patch(:update, params: { broker_carrier: ach_attributes, id: broker_carrier.id }) }

    it { is_expected.to(redirect_to([:broker, broker_carrier])) }
    it { expect(broker_carrier.reload).to(have_attributes(ach_attributes)) }
  end

  describe 'PATCH #update_tariff' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:from_area) { Area.create!(name: 'California, US') }
    let(:params) { { broker_carrier: { pricing_rules_attributes: [pricing_rule_attributes] }, id: broker_carrier.id } }
    let(:pricing_rule_attributes) do
      { cost_per_pallet: '100', from_area_id: from_area.id, max_pallets: '', min_pallets: '1', to_area_id: to_area.id }
    end
    let(:to_area) { Area.create!(name: 'Texas, US') }

    before { patch(:update_tariff, params:) }

    it { is_expected.to(redirect_to(tariff_broker_broker_carrier_path(broker_carrier))) }
    it { expect(broker_carrier.pricing_rules.pluck(:from_area_id, :to_area_id)).to(eq([[from_area.id, to_area.id]])) }
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
