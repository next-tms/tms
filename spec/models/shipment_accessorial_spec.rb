require 'rails_helper'

RSpec.describe(ShipmentAccessorial) do
  let(:shipment_accessorial) { described_class.new }

  describe '#accessorial_key' do
    let(:accessorial) { build(:accessorial, transponder_code: 'liftgate_delivery') }

    it { expect(shipment_accessorial.accessorial_key).to(be_nil) }
    it { expect(described_class.new(accessorial:).accessorial_key).to(eq('liftgate_delivery')) }
  end

  describe '#accessorial_key=' do
    context 'with an accessorial ID' do
      let(:accessorial) { create(:accessorial) }

      before { shipment_accessorial.accessorial_key = accessorial.id.to_s }

      it { expect(shipment_accessorial.accessorial).to(eq(accessorial)) }
    end

    context 'with a Transponder code' do
      before { shipment_accessorial.accessorial_key = 'liftgate_delivery' }

      it { expect(shipment_accessorial.accessorial).to(have_attributes(new_record?: true, transponder_code: 'liftgate_delivery')) }
    end

    context 'with a Transponder code that has an accessorial' do
      let!(:accessorial) { create(:accessorial, transponder_code: 'liftgate_delivery') }

      before { shipment_accessorial.accessorial_key = 'liftgate_delivery' }

      it { expect(shipment_accessorial.accessorial).to(eq(accessorial)) }
    end

    context 'with an unknown code' do
      before { shipment_accessorial.accessorial_key = 'unknown' }

      it { expect(shipment_accessorial.accessorial).to(be_nil) }
    end
  end

  describe '#save' do
    let(:shipment) { create(:shipment) }

    before { shipment.shipment_accessorials.create!(accessorial_key: 'liftgate_delivery') }

    it { expect(Accessorial.where(transponder_code: 'liftgate_delivery').count).to(eq(1)) }
    it { expect(shipment.reload.accessorials.map(&:transponder_code)).to(eq(['liftgate_delivery'])) }

    context 'when the accessorial has an upcharge' do
      subject { shipment.shipment_accessorials.create!(accessorial:, cost: 100).charge }

      let(:accessorial) { create(:accessorial, upcharge_cents: 500, upcharge_percent: 10) }

      it { is_expected.to(eq(Money.from_amount(115))) }
    end
  end
end
