require 'rails_helper'

RSpec.describe(EBOL::Importer::Accessorials) do
  subject(:accessorials) { described_class.new(['LFTD', 'XYZ'], shipment) }

  let(:shipment) { create(:shipment, :usd, picked_up_at: nil) }

  describe '#accessorials' do
    it { expect(accessorials.accessorials.map(&:transponder_code)).to(eq(['liftgate_delivery'])) }

    context 'when the broker renamed the accessorial' do
      let!(:accessorial) { create(:accessorial, name: 'Lift gate delivery', transponder_code: 'liftgate_delivery') }

      it { expect(accessorials.accessorials).to(eq([accessorial])) }
    end
  end

  describe '#shipment_accessorials_attributes' do
    let(:accessorial) { accessorials.accessorials.sole }

    it { expect(accessorials.shipment_accessorials_attributes).to(eq([{ accessorial: }])) }

    context 'when the shipment already has the accessorial' do
      before do
        shipment.shipment_accessorials.create!(accessorial: create(:accessorial, code: 'LIFT', transponder_code: 'liftgate_delivery'))
      end

      it { expect(accessorials.shipment_accessorials_attributes).to(be_empty) }
    end

    context 'when the shipment has an accessorial that the request drops' do
      let(:shipment_accessorial) do
        shipment.shipment_accessorials.create!(accessorial: create(:accessorial, transponder_code: 'liftgate_delivery'))
      end

      before { shipment_accessorial }

      it do
        expect(described_class.new([], shipment).shipment_accessorials_attributes).to(
          eq([{ _destroy: true, id: shipment_accessorial.id }])
        )
      end
    end
  end

  describe '#unsupported_codes' do
    it { expect(accessorials.unsupported_codes).to(eq(['XYZ'])) }
  end
end
