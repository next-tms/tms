# == Schema Information
#
# Table name: pricing_rules
#
# @!attribute id
#   @return []
# @!attribute cost_per_pallet_cents
#   @return [Integer]
# @!attribute cost_per_pallet_currency
#   @return [String]
# @!attribute max_pallets
#   @return [Integer]
# @!attribute min_pallets
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute from_area_id
#   @return []
# @!attribute to_area_id
#   @return []
#
# Indexes
#
#  index_pricing_rules_on_broker_carrier_id  (broker_carrier_id)
#  index_pricing_rules_on_from_area_id       (from_area_id)
#  index_pricing_rules_on_max_pallets        (max_pallets)
#  index_pricing_rules_on_min_pallets        (min_pallets)
#  index_pricing_rules_on_to_area_id         (to_area_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (from_area_id => areas.id)
#  fk_rails_...  (to_area_id => areas.id)
#
require 'rails_helper'

# == Schema Information
#
# Table name: pricing_rules
#
# @!attribute id
#   @return []
# @!attribute cost_per_pallet_cents
#   @return [Integer]
# @!attribute cost_per_pallet_currency
#   @return [String]
# @!attribute max_pallets
#   @return [Integer]
# @!attribute min_pallets
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute from_area_id
#   @return []
# @!attribute to_area_id
#   @return []
#
# Indexes
#
#  index_pricing_rules_on_broker_carrier_id  (broker_carrier_id)
#  index_pricing_rules_on_from_area_id       (from_area_id)
#  index_pricing_rules_on_max_pallets        (max_pallets)
#  index_pricing_rules_on_min_pallets        (min_pallets)
#  index_pricing_rules_on_to_area_id         (to_area_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (from_area_id => areas.id)
#  fk_rails_...  (to_area_id => areas.id)
#
RSpec.describe(PricingRule) do
  subject(:pricing_rule) { build(:pricing_rule, broker_carrier:, from_area:, max_pallets: 4, min_pallets: 1, to_area:) }

  let(:broker_carrier) { create(:broker_carrier) }
  let(:from_area) { Area.create!(name: 'California, US') }
  let(:to_area) { Area.create!(name: 'Texas, US') }

  describe 'relationships' do
    it { is_expected.to(belong_to(:broker_carrier)) }
    it { is_expected.to(belong_to(:from_area).class_name('Area')) }
    it { is_expected.to(belong_to(:to_area).class_name('Area')) }
  end

  describe 'validations' do
    before { broker_carrier.pricing_rules << pricing_rule }

    context 'when another rule on the same lane has an overlapping pallet range' do
      before { broker_carrier.pricing_rules.build(cost_per_pallet: Money.new(100), from_area:, max_pallets: 6, min_pallets: 3, to_area:) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when another rule on the reverse lane has an overlapping pallet range' do
      before do
        broker_carrier
          .pricing_rules
          .build(cost_per_pallet: Money.new(100), from_area: to_area, max_pallets: 6, min_pallets: 3, to_area: from_area)
      end

      it { is_expected.to(be_valid) }
    end

    context 'when the cost per pallet is zero' do
      before { pricing_rule.cost_per_pallet = Money.new(0) }

      it { is_expected.not_to(be_valid) }
    end
  end

  describe '#lane' do
    it { expect(pricing_rule.lane).to(eq([from_area, to_area])) }
  end

  describe '#overlap?' do
    let(:other_from_area) { from_area }
    let(:other_min_pallets) { 3 }
    let(:other_record) { build(:pricing_rule, from_area: other_from_area, min_pallets: other_min_pallets, to_area:) }

    it { expect(pricing_rule.overlap?(other_record)).to(be(true)) }
    it { expect(pricing_rule.overlap?(pricing_rule)).to(be(false)) }

    context 'when the pallet ranges do not overlap' do
      let(:other_min_pallets) { 5 }

      it { expect(pricing_rule.overlap?(other_record)).to(be(false)) }
    end

    context 'when the lanes differ' do
      let(:other_from_area) { Area.create!(name: 'Nevada, US') }

      it { expect(pricing_rule.overlap?(other_record)).to(be(false)) }
    end
  end

  describe '#pallets_range' do
    it { expect(pricing_rule.pallets_range).to(eq(1..4)) }

    context 'when the pallet counts are blank' do
      before { pricing_rule.assign_attributes(max_pallets: nil, min_pallets: nil) }

      it { expect(pricing_rule.pallets_range).to(eq(-1..Float::INFINITY)) }
    end
  end

  describe '#same_lane?' do
    let(:other_record) { build(:pricing_rule, from_area:, to_area:) }

    it { expect(pricing_rule.same_lane?(other_record)).to(be(true)) }

    context 'when the to area differs' do
      before { other_record.to_area = from_area }

      it { expect(pricing_rule.same_lane?(other_record)).to(be(false)) }
    end

    context 'when the from area is blank' do
      before { pricing_rule.from_area = nil }

      it { expect(pricing_rule.same_lane?(other_record)).to(be(false)) }
    end
  end
end
