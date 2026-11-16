require 'rails_helper'

RSpec.describe(Freightview) do
  let(:broker_accessorials) { codes.map { |code| build(:broker_accessorial, accessorial: build(:accessorial, freight_kit_code: code)) } }
  let(:codes) { [] }
  let(:shipment) { build(:shipment, broker_accessorials:, status:) }
  let(:status) { :quoted }

  describe '.decode' do
    it { expect(described_class.decode('limited access')).to(eq(:limited_access)) }
    it { expect(described_class.decode(nil)).to(eq(:'')) }
  end

  describe '.decode_keys' do
    let(:decoded) { { bol_number: '1', items: [{ weight_uom: 'lbs' }] } }
    let(:encoded) { { 'bolNumber' => '1', 'items' => [{ 'weightUOM' => 'lbs' }] } }

    it { expect(described_class.decode_keys(encoded)).to(eq(decoded)) }
  end

  describe '.encode_keys' do
    let(:decoded) { { bol_number: '1', items: [{ nmfc_sub_number: 2 }] } }
    let(:encoded) { { 'bolNumber' => '1', 'items' => [{ 'nmfcSubNumber' => 2 }] } }

    it { expect(described_class.encode_keys(decoded)).to(eq(encoded)) }
  end

  describe '.location_accessorials' do
    let(:codes) { ['inside_pickup', 'liftgate_delivery', 'limited_access_delivery', 'notify_before_delivery'] }

    it { expect(described_class.location_accessorials(shipment, :destination)).to(eq(%i[liftgate notify limited_access])) }
    it { expect(described_class.location_accessorials(shipment, :origin)).to(eq([:inside])) }
  end

  describe '.packaging_type' do
    it { expect(described_class.packaging_type(build(:packaging, freight_kit_type: 'crate'))).to(eq(:crate)) }
    it { expect(described_class.packaging_type(build(:packaging, freight_kit_type: 'truckload'))).to(eq(:piece)) }
    it { expect(described_class.packaging_type(nil)).to(eq(:piece)) }
  end

  describe '.ship_type' do
    let(:codes) { ['residential_delivery'] }

    it { expect(described_class.ship_type(shipment, :destination)).to(eq(:residential)) }
    it { expect(described_class.ship_type(shipment, :origin)).to(be_nil) }
  end

  describe '.shipment_status' do
    it { expect(described_class.shipment_status(shipment)).to(eq(:pending)) }

    context 'when the shipment is out for delivery' do
      let(:status) { :out_for_delivery }

      it { expect(described_class.shipment_status(shipment)).to(eq(:picked_up)) }
    end
  end

  describe '.time' do
    it { expect(described_class.time('4:30 PM')).to(eq('16:30')) }
    it { expect(described_class.time('')).to(be_nil) }
  end

  describe '.tracking_status' do
    it { expect(described_class.tracking_status(shipment)).to(eq(:pending)) }

    context 'when the shipment is dispatched' do
      let(:status) { :dispatched }

      it { expect(described_class.tracking_status(shipment)).to(eq(:enroute_to_pickup)) }
    end
  end
end
