# == Schema Information
#
# Table name: items
#
# @!attribute id
#   @return []
# @!attribute declared_freight_class
#   @return [Float]
# @!attribute desc
#   @return [String]
# @!attribute h
#   @return [Integer]
# @!attribute hazmat
#   @return [Boolean]
# @!attribute l
#   @return [Integer]
# @!attribute nmfc
#   @return [String]
# @!attribute quantity
#   @return [Integer]
# @!attribute refrigerated
#   @return [Boolean]
# @!attribute w
#   @return [Integer]
# @!attribute weight
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute packaging_id
#   @return [Integer]
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_items_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#
require 'rails_helper'

RSpec.describe(Item) do
  subject(:item) { build(:item, declared_freight_class: 70, h: 12, l: 12, packaging:, quantity: 1, w: 12, weight: 50) }

  let(:packaging) { build(:packaging, name: 'pallet') }

  describe '#calculated_freight_class' do
    it { expect(item.calculated_freight_class).to(eq(60)) }

    context 'when the item is light for its size' do
      before { item.assign_attributes(h: 24, l: 24, w: 24, weight: 4) }

      it { expect(item.calculated_freight_class).to(eq(400)) }
    end

    context 'when a dimension is missing' do
      before { item.l = nil }

      it { expect(item.calculated_freight_class).to(be_nil) }
    end
  end

  describe '#declared_freight_class' do
    it { expect(item.declared_freight_class).to(eq(70)) }

    context 'when it is blank' do
      before { item.declared_freight_class = nil }

      it { expect(item.declared_freight_class).to(be_nil) }
    end
  end

  describe '#measured_h' do
    it { expect(item.measured_h).to(eq(Measured::Length.new(12, :in))) }

    context 'without a height' do
      before { item.h = nil }

      it { expect(item.measured_h).to(be_nil) }
    end
  end

  describe '#measured_h=' do
    before { item.measured_h = Measured::Length.new(100, :cm) }

    it { expect(item.h).to(eq(40)) }
  end

  describe '#measured_l' do
    it { expect(item.measured_l).to(eq(Measured::Length.new(12, :in))) }
  end

  describe '#measured_l=' do
    before { item.measured_l = Measured::Length.new(1, :m) }

    it { expect(item.l).to(eq(40)) }
  end

  describe '#measured_w' do
    it { expect(item.measured_w).to(eq(Measured::Length.new(12, :in))) }
  end

  describe '#measured_w=' do
    before { item.measured_w = Measured::Length.new(2, :ft) }

    it { expect(item.w).to(eq(24)) }

    context 'with nil' do
      before { item.measured_w = nil }

      it { expect(item.w).to(be_nil) }
    end
  end

  describe '#measured_weight' do
    it { expect(item.measured_weight).to(eq(Measured::Weight.new(50, :lb))) }
  end

  describe '#measured_weight=' do
    before { item.measured_weight = Measured::Weight.new(100, :kg) }

    it { expect(item.weight).to(eq(221)) }
  end

  describe '#packaging_name' do
    it { expect(item.packaging_name).to(eq('pallet')) }

    context 'when there is no packaging' do
      let(:packaging) { nil }

      it { expect(item.packaging_name).to(be_nil) }
    end
  end

  describe '#pallet_or_crate?' do
    it { expect(item.pallet_or_crate?).to(be(true)) }

    context 'when the packaging is loose' do
      let(:packaging) { build(:packaging, name: 'box') }

      it { expect(item.pallet_or_crate?).to(be(false)) }
    end
  end

  describe 'validations' do
    it { is_expected.to(allow_values(nil, '', '12345', '1234-5').for(:nmfc)) }
    it { is_expected.not_to(allow_value('123').for(:nmfc).with_message('is not in the correct format')) }
  end
end
