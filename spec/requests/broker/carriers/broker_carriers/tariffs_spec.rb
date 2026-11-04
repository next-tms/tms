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
    let(:from_area) { Area.create!(name: 'California, US') }
    let(:pricing_rule_attributes) do
      { cost_per_pallet: '100', from_area_id: from_area.id, max_pallets: '', min_pallets: '1', to_area_id: to_area.id }
    end
    let(:to_area) { Area.create!(name: 'Texas, US') }

    before { patch(path, params: { broker_carrier: { pricing_rules_attributes: [pricing_rule_attributes] } }) }

    it { is_expected.to(redirect_to(path)) }
    it { expect(broker_carrier.pricing_rules.pluck(:from_area_id, :to_area_id)).to(eq([[from_area.id, to_area.id]])) }
    it { expect(flash[:success]).to(eq('Tariff updated')) }
  end
end
