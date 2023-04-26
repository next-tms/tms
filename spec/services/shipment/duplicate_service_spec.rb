# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shipment::DuplicateService do
  let!(:shipment) { create(:shipment, carrier_cost_currency: 'USD', carrier_charge_currency: 'USD') }
  let!(:broker_accessorial) { create(:broker_accessorial) }
  let!(:item) { create(:item) }

  describe '#call' do
    subject { described_class.new(shipment:).call }

    before do
      shipment.shipment_items.create(item:)
      shipment.shipment_broker_accessorials.create(broker_accessorial:)
    end

    it 'creates new shipment' do
      expect { subject }.to change { Shipment.count }.by(1)
    end

    it 'duplicates shipper and receiver address, items and broker accessorials' do
      new_shipment = subject
      except_attrs = %w[id created_at updated_at]

      expect(shipment.receiver_address.pretty('')).to eq(new_shipment.receiver_address.pretty(''))
      expect(shipment.shipper_address.pretty('')).to eq(new_shipment.shipper_address.pretty(''))

      item.attributes.each do |k, v|
        next if except_attrs.include?(k)

        expect(new_shipment.items.first.send(k)).to eq(v)
      end

      broker_accessorial.attributes.each do |k, v|
        next if except_attrs.include?(k)

        expect(new_shipment.broker_accessorials.first.send(k)).to eq(broker_accessorial.send(k))
      end
    end

    it 'stores nil on nullable attrs' do
      new_shipment = subject

      described_class::NULLABLE_ATTRS.each do |attr|
        expect(new_shipment.send(attr)).to be_nil
      end
    end
  end
end
