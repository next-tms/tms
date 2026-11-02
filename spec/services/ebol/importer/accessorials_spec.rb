require 'rails_helper'

RSpec.describe(EBOL::Importer::Accessorials) do
  subject(:accessorials) { described_class.new(['LFTD', 'XYZ'], shipment) }

  let(:shipment) { create(:shipment, :usd, picked_up_at: nil) }
  let!(:accessorial) { create(:accessorial, freight_kit_code: 'liftgate_delivery', name: 'Lift gate delivery') }

  describe '#broker_accessorials' do
    it { expect(accessorials.broker_accessorials.map(&:accessorial)).to(eq([accessorial])) }
  end

  describe '#shipment_broker_accessorials_attributes' do
    let(:broker_accessorial) { accessorials.broker_accessorials.sole }

    it { expect(accessorials.shipment_broker_accessorials_attributes).to(include({ broker_accessorial_id: broker_accessorial.id })) }

    context 'when the shipment already has the accessorial' do
      before { shipment.shipment_broker_accessorials.create!(broker_accessorial:) }

      it { expect(accessorials.shipment_broker_accessorials_attributes).to(be_empty) }
    end

    context 'when the shipment has an accessorial that the request drops' do
      let(:shipment_broker_accessorial) { shipment.shipment_broker_accessorials.create!(broker_accessorial:) }

      before { shipment_broker_accessorial }

      it do
        expect(described_class.new([], shipment).shipment_broker_accessorials_attributes).to(
          eq([{ _destroy: true, id: shipment_broker_accessorial.id }])
        )
      end
    end
  end

  describe '#unsupported_codes' do
    it { expect(accessorials.unsupported_codes).to(eq(['XYZ'])) }
  end
end
