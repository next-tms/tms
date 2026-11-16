require 'rails_helper'

RSpec.describe(PricingRule) do
  subject(:pricing_rule) { build(:pricing_rule, broker_carrier:, lane_id:, max_pallets: 4, min_pallets: 1) }

  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }
  let(:lane_id) { '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01' }
  let(:other_lane_id) { '7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02' }

  describe 'relationships' do
    it { is_expected.to(belong_to(:broker_carrier)) }
  end

  describe 'validations' do
    before { broker_carrier.pricing_rules << pricing_rule }

    it { is_expected.to(be_valid) }

    context 'when another rule on the same lane has an overlapping pallet range' do
      before { broker_carrier.pricing_rules.build(cost_per_pallet: Money.new(100), lane_id:, max_pallets: 6, min_pallets: 3) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when another rule on another lane has an overlapping pallet range' do
      before { broker_carrier.pricing_rules.build(cost_per_pallet: Money.new(100), lane_id: other_lane_id, max_pallets: 6, min_pallets: 3) }

      it { is_expected.to(be_valid) }
    end

    context 'when the cost per pallet is zero' do
      before { pricing_rule.cost_per_pallet = Money.new(0) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the lane is blank' do
      let(:lane_id) { nil }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the lane is not in Transponder' do
      let(:lane_id) { 'removed' }

      before { pricing_rule.validate }

      it { expect(pricing_rule.errors.of_kind?(:lane, :invalid)).to(be(true)) }
    end

    context 'when the lane belongs to another carrier' do
      let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :tql)) }

      before { pricing_rule.validate }

      it { expect(pricing_rule.errors.of_kind?(:lane, :inclusion)).to(be(true)) }
    end
  end

  describe '#lane' do
    it { expect(pricing_rule.lane).to(eq(Transponder::ORM::Lane.find(lane_id))) }
  end

  describe '#overlap?' do
    let(:other_record) { build(:pricing_rule, broker_carrier:, lane_id: other_record_lane_id, min_pallets: other_min_pallets) }
    let(:other_min_pallets) { 3 }
    let(:other_record_lane_id) { lane_id }

    it { expect(pricing_rule.overlap?(other_record)).to(be(true)) }
    it { expect(pricing_rule.overlap?(pricing_rule)).to(be(false)) }

    context 'when the pallet ranges do not overlap' do
      let(:other_min_pallets) { 5 }

      it { expect(pricing_rule.overlap?(other_record)).to(be(false)) }
    end

    context 'when the lanes differ' do
      let(:other_record_lane_id) { other_lane_id }

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
    let(:other_record) { build(:pricing_rule, broker_carrier:, lane_id:) }

    it { expect(pricing_rule.same_lane?(other_record)).to(be(true)) }

    context 'when the lane differs' do
      before { other_record.lane_id = other_lane_id }

      it { expect(pricing_rule.same_lane?(other_record)).to(be(false)) }
    end

    context 'when the lane is blank' do
      before { pricing_rule.lane_id = nil }

      it { expect(pricing_rule.same_lane?(other_record)).to(be(false)) }
    end
  end
end
