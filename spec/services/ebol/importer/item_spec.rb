require 'rails_helper'

RSpec.describe(EBOL::Importer::Item) do
  describe '.call' do
    subject(:attributes) { described_class.call(ActionController::Parameters.new(handling_unit).permit!) }

    let(:handling_unit) do
      {
        count: 2,
        dimensionsUnit: 'Inches',
        height: 40,
        length: 48,
        lineItems: [{ classification: '70', description: 'Widgets', hazardous: true, nmfc: '12345', nmfcSub: '01' }],
        type: 'PAT',
        weight: 900,
        weightUnit: 'Pounds',
        width: 40
      }
    end
    let!(:packaging) { create(:packaging, freight_kit_type: 'pallet') }

    it { is_expected.to(include(declared_freight_class: 70.0, desc: 'Widgets', hazmat: true, measured_h: Measured::Length.new(40, :in), nmfc: '12345-01')) }
    it { is_expected.to(include(measured_l: Measured::Length.new(48, :in), measured_w: Measured::Length.new(40, :in), measured_weight: Measured::Weight.new(900, :lb))) }
    it { is_expected.to(include(packaging:, quantity: 2)) }

    context 'with metric units' do
      before { handling_unit.merge!(dimensionsUnit: 'Centimeters', length: 100, weight: 100, weightUnit: 'Kilograms') }

      it { is_expected.to(include(measured_l: Measured::Length.new(100, :cm), measured_weight: Measured::Weight.new(100, :kg))) }
    end

    context 'with an unknown unit' do
      before { handling_unit.merge!(dimensionsUnit: 'Cubits', weightUnit: 'Stone') }

      it { is_expected.to(include(measured_l: Measured::Length.new(48, :in), measured_weight: Measured::Weight.new(900, :lb))) }
    end

    context 'without a weight' do
      before { handling_unit.delete(:weight) }

      it { is_expected.to(include(measured_weight: nil)) }
    end

    context 'without line items' do
      before { handling_unit.delete(:lineItems) }

      it { is_expected.to(include(declared_freight_class: nil, desc: 'Freight', hazmat: false, nmfc: nil)) }
    end
  end
end
