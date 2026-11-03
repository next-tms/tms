require 'rails_helper'
require Rails.root.join('db/migrate/20261026020142_move_carrier_areas_to_pricing_rules')

RSpec.describe(MoveCarrierAreasToPricingRules) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:california) { Area.create!(name: 'California, US') }
  let(:carrier_areas) { described_class::CarrierArea.order(:from_area_id).pluck(:carrier_id, :from_area_id, :to_area_id) }
  let(:carrier_id) { broker_carrier.carrier_id }
  let(:columns) { ActiveRecord::Base.connection.columns(:pricing_rules).map(&:name) }
  let(:lanes) { pricing_rules.map { |pricing_rule| [pricing_rule.id, pricing_rule.from_area_id, pricing_rule.to_area_id] } }
  let(:migration) { described_class.new }
  let(:nevada) { Area.create!(name: 'Nevada, US') }
  let(:other_broker_carrier) { create(:broker_carrier, carrier: broker_carrier.carrier) }
  let(:pricing_rule_areas) { described_class::PricingRule.order(:id).pluck(:id, :from_area_id, :to_area_id) }
  let!(:pricing_rules) do
    [
      create(:pricing_rule, broker_carrier:, from_area: california, to_area: texas),
      create(:pricing_rule, broker_carrier: other_broker_carrier, from_area: california, to_area: texas),
      create(:pricing_rule, broker_carrier:, from_area: texas, to_area: nevada)
    ]
  end
  let(:texas) { Area.create!(name: 'Texas, US') }

  before { ActiveRecord::Migration.suppress_messages { migration.down } }

  after do
    described_class::CarrierArea.reset_column_information
    described_class::PricingRule.reset_column_information
  end

  describe '#down' do
    let(:pricing_rule_carrier_areas) do
      described_class::PricingRule.order(:id).map do |pricing_rule|
        carrier_area = described_class::CarrierArea.find(pricing_rule.carrier_area_id)
        [pricing_rule.id, carrier_area.from_area_id, carrier_area.to_area_id]
      end
    end

    it { expect(carrier_areas).to(eq([[carrier_id, california.id, texas.id], [carrier_id, texas.id, nevada.id]])) }
    it { expect(pricing_rule_carrier_areas).to(eq(lanes)) }
    it { expect(columns).not_to(include('from_area_id', 'to_area_id')) }
  end

  describe '#up' do
    before { ActiveRecord::Migration.suppress_messages { migration.up } }

    it { expect(pricing_rule_areas).to(eq(lanes)) }
    it { expect(columns).not_to(include('carrier_area_id')) }
    it { expect(ActiveRecord::Base.connection.table_exists?(:carrier_areas)).to(be(false)) }
  end
end
