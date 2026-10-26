require 'rails_helper'

RSpec.describe(Shipment::RatesService::FromPricingRules) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:from_area) { Area.create!(name: 'California, US') }
  let(:receiver_region_iso31662) { 'US-TX' }
  let(:to_area) { Area.create!(name: 'Texas, US') }

  let(:shipment) do
    create(
      :shipment,
      broker_carrier:,
      receiver_address: create(:address, region_iso31662: receiver_region_iso31662),
      shipper_address: create(:address, region_iso31662: 'US-CA'),
    )
  end

  before do
    from_area.locations.create!(region_iso31662: 'US-CA')
    to_area.locations.create!(region_iso31662: 'US-TX')

    broker_carrier.pricing_rules.create!(cost_per_pallet: Money.new(10_000), from_area:, min_pallets: 1, to_area:)

    create(:item, packaging: create(:packaging, name: 'pallet'), shipment:)
  end

  describe '#call' do
    let(:rates) { described_class.new(broker_carrier, shipment, save: false).call }

    it { expect(rates.size).to(eq(1)) }
    it { expect(rates.first.cost).to(eq(Money.new(10_000))) }

    context 'when the rule is for the reverse lane' do
      before { broker_carrier.pricing_rules.first.update!(from_area: to_area, to_area: from_area) }

      it { expect(rates).to(be_empty) }
    end

    context 'when the receiver region has no location' do
      let(:receiver_region_iso31662) { 'US-WY' }

      it { expect(rates).to(be_empty) }
    end
  end
end
