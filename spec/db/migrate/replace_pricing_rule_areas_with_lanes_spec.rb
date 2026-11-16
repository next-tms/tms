require 'rails_helper'
require Rails.root.join('db/migrate/20261116002705_replace_pricing_rule_areas_with_lanes')

RSpec.describe(ReplacePricingRuleAreasWithLanes) do
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }
  let(:columns) { ActiveRecord::Base.connection.columns(:pricing_rules).map(&:name) }
  let(:lane_id) { '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01' }
  let(:migration) { described_class.new }
  let(:pricing_rule_lane_ids) { described_class::PricingRule.order(:id).pluck(:lane_id) }
  let(:pricing_rule_regions) do
    described_class::PricingRule.order(:id).map do |pricing_rule|
      [pricing_rule.from_area, pricing_rule.to_area].map { |area| area.locations.sole.region_iso31662 }
    end
  end

  before do
    described_class::PricingRule.create!(broker_carrier_id: broker_carrier.id, cost_per_pallet_cents: 10_000, lane_id:)

    ActiveRecord::Migration.suppress_messages { migration.down }
  end

  after do
    [
      described_class::Area,
      described_class::Location,
      described_class::LocationArea,
      described_class::PricingRule
    ].each(&:reset_column_information)
  end

  describe '#down' do
    it { expect(pricing_rule_regions).to(eq([['US-CA', 'US-TX']])) }
    it { expect(described_class::Area.pluck(:name)).to(contain_exactly('CA, US', 'TX, US')) }
    it { expect(columns).not_to(include('lane_id')) }

    context 'when a pricing rule has a lane that is not in FreightKit' do
      before do
        ActiveRecord::Migration.suppress_messages { migration.up }
        described_class::PricingRule.reset_column_information
        described_class::PricingRule.create!(broker_carrier_id: broker_carrier.id, cost_per_pallet_cents: 10_000, lane_id: 'unknown')
      end

      it { expect { ActiveRecord::Migration.suppress_messages { migration.down } }.to(raise_error(ActiveRecord::IrreversibleMigration)) }
    end
  end

  describe '#up' do
    let(:carrier) { described_class::Carrier.find(broker_carrier.carrier_id) }
    let(:nevada) { described_class::Area.create!(locations: [described_class::Location.new(region_iso31662: 'US-NV')], name: 'NV, US') }
    let(:unmapped_pricing_rule) do
      described_class::PricingRule.first.dup.tap { |pricing_rule| pricing_rule.update!(to_area_id: nevada.id) }
    end

    before { ActiveRecord::Migration.suppress_messages { migration.up } }

    it { expect(pricing_rule_lane_ids).to(eq([lane_id])) }
    it { expect(columns).not_to(include('from_area_id', 'to_area_id')) }
    it { expect(ActiveRecord::Base.connection.table_exists?(:areas)).to(be(false)) }
    it { expect(ActiveRecord::Base.connection.table_exists?(:location_areas)).to(be(false)) }
    it { expect(ActiveRecord::Base.connection.table_exists?(:locations)).to(be(false)) }

    context 'when the carrier is linked to Transponder only by SCAC' do
      before do
        ActiveRecord::Migration.suppress_messages { migration.down }
        carrier.update!(transponder_id: nil)
        ActiveRecord::Migration.suppress_messages { migration.up }
      end

      it { expect(pricing_rule_lane_ids).to(eq([lane_id])) }
    end

    context 'when a pricing rule has no FreightKit lane' do
      before do
        ActiveRecord::Migration.suppress_messages { migration.down }
        described_class::PricingRule.reset_column_information
        unmapped_pricing_rule
        ActiveRecord::Migration.suppress_messages { migration.up }
      end

      it { expect(pricing_rule_lane_ids).to(eq([lane_id])) }
    end
  end
end
