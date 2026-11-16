require 'rails_helper'

RSpec.describe(Shipment::RatesService::FromPricingRules) do
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }
  let(:lane_id) { '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01' }
  let(:matching_lane_ids) { [lane_id] }
  let(:other_lane_id) { '7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02' }

  let(:shipment) do
    create(
      :shipment,
      broker_carrier:,
      pro: '12345678901',
      receiver_address: create(:address, region_iso31662: 'US-TX'),
      shipper_address: create(:address, region_iso31662: 'US-CA')
    )
  end

  before do
    broker_carrier.pricing_rules.create!(cost_per_pallet: Money.new(10_000), lane_id:, min_pallets: 1)

    create(:item, packaging: create(:packaging, name: 'pallet'), shipment:)

    stub_transponder_matching_lanes(*matching_lane_ids)
  end

  describe '#call' do
    let(:rates) { described_class.new(broker_carrier, shipment, save: false).call }

    it { expect(rates.size).to(eq(1)) }
    it { expect(rates.first.cost).to(eq(Money.new(10_000))) }

    context 'when no lane matches' do
      let(:matching_lane_ids) { [] }

      it { expect(rates).to(be_empty) }
    end

    context 'when a more specific lane has no pricing rule' do
      let(:matching_lane_ids) { [other_lane_id, lane_id] }

      it { expect(rates.first.cost).to(eq(Money.new(10_000))) }
    end

    context 'when several matching lanes have pricing rules' do
      let(:matching_lane_ids) { [other_lane_id, lane_id] }

      before { broker_carrier.pricing_rules.create!(cost_per_pallet: Money.new(20_000), lane_id: other_lane_id, min_pallets: 1) }

      it { expect(rates.map(&:cost)).to(eq([Money.new(20_000)])) }
    end

    context 'when the broker carrier has a quote padding' do
      before { broker_carrier.update!(quote_padding: Money.new(500)) }

      it { expect(rates.first.cost).to(eq(Money.new(10_500))) }
    end

    context 'when the carrier has territories and no lanes' do
      let(:rates) { described_class.new(tql_broker_carrier, shipment, save: false).call }
      let(:serve) { true }
      let(:tql_broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :tql)) }

      before { stub_transponder_serve(serve) }

      it { expect(rates.map(&:cost)).to(eq([Money.new(0)])) }
      it { expect(rates.first).to(be_pricing_rule) }

      context 'when the territories do not serve the shipment' do
        let(:serve) { false }

        it { expect(rates).to(be_empty) }
      end

      context 'when the carrier has no territories' do
        let(:carriers) do
          JSON.parse(TransponderCarriers::FIXTURE_PATH.read).tap do |original_hash|
            original_hash.dig('data', 'fetchCarriers').each { |carrier| carrier['territories'] = [] }
          end
        end

        before { stub_transponder_carriers(carriers) }

        it { expect(rates).to(be_empty) }
      end
    end

    context 'when the carrier has no Transponder carrier' do
      before { broker_carrier.carrier.update!(transponder_id: nil) }

      it { expect(rates).to(be_empty) }
    end

    context 'when a lane matches without a pricing rule' do
      before { broker_carrier.pricing_rules.delete_all }

      it { expect(rates.map(&:cost)).to(eq([Money.new(0)])) }
      it { expect(rates.first).to(be_pricing_rule) }

      context 'when the broker carrier has a quote padding' do
        before { broker_carrier.update!(quote_padding: Money.new(500)) }

        it { expect(rates.first.cost).to(eq(Money.new(0))) }
      end
    end

    context 'when the pallet count is outside every pallet range' do
      before { broker_carrier.pricing_rules.first.update!(max_pallets: 5, min_pallets: 2) }

      it { expect(rates.map(&:cost)).to(eq([Money.new(0)])) }
    end
  end
end
