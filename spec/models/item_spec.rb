require 'rails_helper'

RSpec.describe(Item) do
  describe '#summary' do
    subject { item.summary }

    let(:h) { 40 }
    let(:item) { build(:item, declared_freight_class: 70, desc: 'Candy Canes', h:, l: 48, packaging:, quantity: 2, w: 40) }
    let(:packaging) { build(:packaging, name: 'pallet') }

    it { is_expected.to(eq('2 pallet Candy Canes 48x40x40 Class 70')) }

    context 'when a dimension is missing' do
      let(:h) { nil }

      it { is_expected.to(eq('2 pallet Candy Canes <Unspecified Dimensions> Class 70')) }
    end

    context 'when packaging is missing' do
      let(:packaging) { nil }

      it { is_expected.to(eq('2 Candy Canes 48x40x40 Class 70')) }
    end
  end
end
