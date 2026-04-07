require 'rails_helper'

RSpec.describe(Shipment::DuplicateService) do
  let!(:shipment) { create(:shipment, carrier_cost_currency: 'USD', carrier_charge_currency: 'USD') }
  let!(:broker_accessorial) { create(:broker_accessorial) }
  let!(:item) { create(:item) }

  describe '#call' do
    subject(:call) { described_class.new(shipment:).call }

    before do
      shipment.shipment_items.create(item:)
      shipment.shipment_broker_accessorials.create(broker_accessorial:)
    end

    it { expect { call }.to(change(Shipment, :count).by(1)) }

    it 'duplicates shipper and receiver address' do
      new_shipment = call
      expect(shipment.receiver_address.pretty('')).to(eq(new_shipment.receiver_address.pretty('')))
      expect(shipment.shipper_address.pretty('')).to(eq(new_shipment.shipper_address.pretty('')))
    end

    it 'duplicates items' do
      new_shipment = call
      except_attrs = [ 'id', 'created_at', 'updated_at' ]
      item.attributes.each do |k, v|
        next if except_attrs.include?(k)

        expect(new_shipment.items.first.send(k)).to(eq(v))
      end
    end

    it 'duplicates broker accessorials' do
      new_shipment = call
      except_attrs = [ 'id', 'created_at', 'updated_at' ]
      broker_accessorial.attributes.each do |k, _v|
        next if except_attrs.include?(k)

        expect(new_shipment.broker_accessorials.first.send(k)).to(eq(broker_accessorial.send(k)))
      end
    end

    it 'stores nil on nullable attrs' do
      new_shipment = call
      described_class::NULLABLE_ATTRS.each do |attr|
        expect(new_shipment.send(attr)).to(be_nil)
      end
    end
  end
end
