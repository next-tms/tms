require 'rails_helper'

RSpec.describe('Broker::Carriers::BrokerCarriers::Tariffs') do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:path) { "/broker/carriers/#{broker_carrier.carrier_id}/accounts/#{broker_carrier.id}/tariff" }

  before do
    seed_settings
    sign_in(create(:root_broker_user))
  end

  describe 'GET /broker/carriers/:carrier_id/accounts/:broker_carrier_id/tariff' do
    before { get(path) }

    it { is_expected.to(have_http_status(:ok)) }
  end

  describe 'PATCH /broker/carriers/:carrier_id/accounts/:broker_carrier_id/tariff' do
    let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }
    let(:lane_id) { '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01' }
    let(:pricing_rule_attributes) { { cost_per_pallet: '100', lane_id:, max_pallets: '', min_pallets: '1' } }

    before { patch(path, params: { broker_carrier: { pricing_rules_attributes: [pricing_rule_attributes] } }) }

    it { is_expected.to(redirect_to(path)) }
    it { expect(broker_carrier.pricing_rules.pluck(:lane_id)).to(eq([lane_id])) }
    it { expect(flash[:success]).to(eq('Tariff updated')) }
  end
end
