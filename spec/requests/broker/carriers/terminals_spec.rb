require 'rails_helper'

RSpec.describe('Broker::Carriers::Terminals') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }
  let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/terminals' do
    let(:filter) { 'texas' }
    let(:terminals_filter) { Broker::Carriers::TerminalsController::FILTER }

    let!(:austin) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier:) }
    let!(:fremont) { Terminal.create!(address: create(:address, city: 'Fremont', region_iso31662: 'US-CA'), carrier:) }

    before { get("/broker/carriers/#{broker_carrier.carrier_id}/terminals", params: { q: { terminals_filter => filter } }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:terminals)).to(contain_exactly(austin)) }

    context 'when the filter is blank' do
      let(:filter) { '' }

      it { expect(assigns(:terminals)).to(contain_exactly(austin, fremont)) }
    end

    context 'when the filter matches a region code' do
      let(:filter) { 'US-CA' }

      it { expect(assigns(:terminals)).to(contain_exactly(fremont)) }
    end

    context 'when the filter matches the address text' do
      let(:filter) { 'fremont' }

      it { expect(assigns(:terminals)).to(contain_exactly(fremont)) }
    end
  end

  describe 'GET /broker/carriers/:carrier_id/terminals with a city and state' do
    let(:state) { 'texas' }
    let!(:terminal) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier:) }

    before do
      Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-CA'), carrier:)
      Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier: create(:carrier))
      get("/broker/carriers/#{broker_carrier.carrier_id}/terminals", params: { city: 'austin', state: })
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:nearby_terminals)).to(contain_exactly(terminal)) }

    context 'when the carrier has no accounts' do
      before { get("/broker/carriers/#{create(:carrier).id}/terminals", params: { city: 'austin', state: }) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:nearby_terminals)).to(be_empty) }
    end

    context 'when the state is an abbreviation' do
      let(:state) { 'tx' }

      it { expect(assigns(:nearby_terminals)).to(contain_exactly(terminal)) }
    end

    context 'when the state is blank' do
      let(:state) { nil }

      it { expect(assigns(:nearby_terminals)).to(be_empty) }
    end

    context 'when Transponder shares a terminal for the carrier' do
      let(:carrier) { create(:carrier, :saia) }

      it { expect(assigns(:nearby_terminals)).to(contain_exactly(terminal, *carrier.transponder_terminals)) }
    end
  end
end
