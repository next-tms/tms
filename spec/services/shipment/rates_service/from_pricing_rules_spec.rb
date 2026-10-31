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
      shipper_address: create(:address, region_iso31662: 'US-CA')
    )
  end

  before do
    from_area.locations.create!(region_iso31662: 'US-CA')
    to_area.locations.create!(region_iso31662: 'US-TX')

    carrier_area = CarrierArea.create!(carrier: broker_carrier.carrier, from_area:, to_area:)
    broker_carrier.pricing_rules.create!(carrier_area:, cost_per_pallet: Money.new(10_000), min_pallets: 1)

    create(:item, packaging: create(:packaging, name: 'pallet'), shipment:)
  end

  describe '#call' do
    let(:rates) { described_class.new(broker_carrier, shipment, save: false).call }

    it { expect(rates.size).to(eq(1)) }

    context 'when the receiver region has no location' do
      let(:receiver_region_iso31662) { 'US-WY' }

      it { expect(rates).to(be_empty) }
    end
  end
end
